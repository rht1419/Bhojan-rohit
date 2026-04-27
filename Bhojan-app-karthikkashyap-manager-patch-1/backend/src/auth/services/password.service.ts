import { Injectable, NotFoundException, Logger } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';
import { RedisService } from '../../redis/redis.service.js';
import { OtpService } from '../../otp/services/otp.service.js';
import { TokenService } from './jwt.service.js';
import { AuditService } from '../../audit/services/audit.service.js';
import { hashPassword } from '../../common/utils/bcrypt.helper.js';
import type { PasswordResetRequestDto } from '../dto/password-reset-request.dto.js';
import type { PasswordResetVerifyDto } from '../dto/password-reset-verify.dto.js';
import { AuditAction, AuditModule } from '@prisma/client';
<<<<<<< HEAD
import { normalizeIndianPhone } from '../../common/utils/phone.helper.js';
=======
>>>>>>> 9164b54b7ae96a96dfb046b32a6f1d92bc55e577

const REFRESH_TTL_SECONDS = 7 * 24 * 60 * 60;

@Injectable()
export class PasswordService {
  private readonly logger = new Logger(PasswordService.name);

  constructor(
    private prisma: PrismaService,
    private redis: RedisService,
    private otp: OtpService,
    private tokens: TokenService,
    private audit: AuditService,
  ) {}

  // ── EP-09: Password Reset Request ─────────────────────────────────────────

  async resetRequest(dto: PasswordResetRequestDto) {
<<<<<<< HEAD
    const phone = normalizeIndianPhone(dto.phone);
    const user = await this.prisma.user.findUnique({ where: { phone } });

    // Always 200 — never reveal whether account exists
    if (!user || user.is_deleted) {
      return { otp_reference: '', message: 'If an account exists, an OTP has been sent' };
    }

    // Rate limit check happens inside sendOtp — let it throw 429 if needed
    await this.otp.sendOtp(phone, 'PASSWORD_RESET');

    await this.audit.log({
      userId: user.id, action: AuditAction.PASSWORD_RESET_REQUESTED,
      module: AuditModule.AUTH, metadata: { phone },
    });

    return { otp_reference: '', message: 'If an account exists, an OTP has been sent' };
=======
    const user = await this.prisma.user.findUnique({ where: { phone: dto.phone } });

    // Always 200 — never reveal whether account exists
    if (!user || user.is_deleted) {
      return { message: 'If an account exists, an OTP has been sent' };
    }

    // Rate limit check happens inside sendOtp — let it throw 429 if needed
    await this.otp.sendOtp(dto.phone, 'PASSWORD_RESET');

    await this.audit.log({
      userId: user.id, action: AuditAction.PASSWORD_RESET_REQUESTED,
      module: AuditModule.AUTH, metadata: { phone: dto.phone },
    });

    return { message: 'If an account exists, an OTP has been sent' };
>>>>>>> 9164b54b7ae96a96dfb046b32a6f1d92bc55e577
  }

  // ── EP-10: Password Reset Verify ──────────────────────────────────────────

  async resetVerify(dto: PasswordResetVerifyDto) {
<<<<<<< HEAD
    const phone = normalizeIndianPhone(dto.phone);
    const user = await this.prisma.user.findUnique({ where: { phone } });
=======
    const user = await this.prisma.user.findUnique({ where: { phone: dto.phone } });
>>>>>>> 9164b54b7ae96a96dfb046b32a6f1d92bc55e577
    if (!user) {
      throw new NotFoundException({ code: 'USER_NOT_FOUND', message: 'Phone number not registered.' });
    }

<<<<<<< HEAD
    await this.otp.verifyOtp(phone, dto.otp, 'PASSWORD_RESET');
=======
    await this.otp.verifyOtp(dto.phone, dto.otp, 'PASSWORD_RESET');
>>>>>>> 9164b54b7ae96a96dfb046b32a6f1d92bc55e577

    const passwordHash = await hashPassword(dto.new_password);
    await this.prisma.user.update({ where: { id: user.id }, data: { password_hash: passwordHash } });

    await this.revokeAllSessions(user.id);

    await Promise.all([
      this.audit.log({ userId: user.id, action: AuditAction.PASSWORD_RESET, module: AuditModule.AUTH }),
      this.audit.log({ userId: user.id, action: AuditAction.ALL_SESSIONS_REVOKED, module: AuditModule.SESSION }),
    ]);

    return { message: 'Password reset successful. Please log in again.' };
  }

  // ── Shared helpers ─────────────────────────────────────────────────────────

  async revokeAllSessions(userId: string): Promise<void> {
    const active = await this.prisma.session.findMany({
      where: { user_id: userId, is_revoked: false },
      select: { id: true, refresh_token: true, expires_at: true },
    });

    if (active.length === 0) return;

    await this.prisma.session.updateMany({
      where: { user_id: userId, is_revoked: false },
      data: { is_revoked: true },
    });

    for (const session of active) {
      const ttl = Math.max(0, Math.floor((session.expires_at.getTime() - Date.now()) / 1000));
      if (ttl > 0) {
        await this.redis.set(`blacklist:${session.refresh_token}`, '1', ttl);
      }
    }
  }
}
