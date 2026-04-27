import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';
import { RedisService } from '../../redis/redis.service.js';
import { OtpService } from '../../otp/services/otp.service.js';
import { AuditService } from '../../audit/services/audit.service.js';
import type { DeleteAccountDto } from '../dto/delete-account.dto.js';
import { AuditAction, AuditModule, DeletionStatus } from '@prisma/client';

@Injectable()
export class DeletionService {
  constructor(
    private prisma: PrismaService,
    private redis: RedisService,
    private otp: OtpService,
    private audit: AuditService,
  ) {}

  // ── EP-13: Account Deletion (DPDP Act 2023) — two-step ───────────────────
  // Step 1 (no otp): send OTP to phone
  // Step 2 (with otp): verify OTP → anonymise PII → revoke sessions

  async deleteAccount(userId: string, dto: DeleteAccountDto) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException({ code: 'USER_NOT_FOUND', message: 'User not found.' });

    // Step 1 — send OTP confirmation
    if (!dto.otp) {
      await this.otp.sendOtp(user.phone, 'DELETION');
      return { message: 'OTP sent to your registered phone. Enter it to confirm account deletion.' };
    }

    // Step 2 — verify OTP and execute deletion
    await this.otp.verifyOtp(user.phone, dto.otp, 'DELETION');

    // Create deletion request (PENDING)
    await this.prisma.accountDeletionRequest.upsert({
      where: { user_id: userId },
      update: { status: DeletionStatus.PENDING, requested_at: new Date(), reason: dto.reason ?? null },
      create: { user_id: userId, reason: dto.reason ?? null, status: DeletionStatus.PENDING },
    });

    // Soft-delete + anonymise PII on users table
    await this.prisma.user.update({
      where: { id: userId },
      data: {
        is_deleted: true,
        is_active: false,
        deleted_at: new Date(),
        phone: `deleted_${userId}`,
        email: `deleted_${userId}@bhojan.deleted`,
      },
    });

    // Anonymise user profile
    await this.prisma.userProfile.updateMany({
      where: { user_id: userId },
      data: {
        full_name: 'Deleted User',
        avatar_url: null,
        department: null,
        floor: null,
        building: null,
      },
    });

    // Revoke all active sessions + blacklist tokens in Redis
    await this.revokeAllSessions(userId);

    // Mark deletion complete
    const now = new Date();
    await this.prisma.accountDeletionRequest.update({
      where: { user_id: userId },
      data: {
        status: DeletionStatus.COMPLETED,
        anonymized_at: now,
        completed_at: now,
      },
    });

    await Promise.all([
      this.audit.log({
        userId, action: AuditAction.ACCOUNT_DELETED, module: AuditModule.AUTH,
        metadata: dto.reason ? { reason: dto.reason } : undefined,
      }),
      this.audit.log({ userId, action: AuditAction.ACCOUNT_ANONYMIZED, module: AuditModule.AUTH }),
    ]);

    return { success: true, message: 'Account deletion processed. You have been logged out.' };
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  private async revokeAllSessions(userId: string): Promise<void> {
    const active = await this.prisma.session.findMany({
      where: { user_id: userId, is_revoked: false },
      select: { id: true, refresh_token: true, expires_at: true },
    });
    if (active.length === 0) return;

    await this.prisma.session.updateMany({
      where: { user_id: userId, is_revoked: false },
      data: { is_revoked: true },
    });

    for (const s of active) {
      const ttl = Math.max(0, Math.floor((s.expires_at.getTime() - Date.now()) / 1000));
      if (ttl > 0) await this.redis.set(`blacklist:${s.refresh_token}`, '1', ttl);
    }
  }
}
