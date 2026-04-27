import {
  Injectable,
  ForbiddenException,
  ConflictException,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';
import { RedisService } from '../../redis/redis.service.js';
import { OtpService } from '../../otp/services/otp.service.js';
import { TokenService } from './jwt.service.js';
import { AuditService } from '../../audit/services/audit.service.js';
import type { UpgradeEmployeeDto } from '../dto/upgrade-employee.dto.js';
import { AuditAction, AuditModule, Role } from '@prisma/client';

const REFRESH_TTL_SECONDS = 7 * 24 * 60 * 60;

@Injectable()
export class UpgradeService {
  constructor(
    private prisma: PrismaService,
    private redis: RedisService,
    private otp: OtpService,
    private tokens: TokenService,
    private audit: AuditService,
  ) {}

  // ── EP-14: Guest → Employee Upgrade (two-step) ────────────────────────────
  // Step 1 (no otp): validate roster, send OTP
  // Step 2 (with otp): verify OTP, apply upgrade, issue new tokens

  async upgrade(userId: string, currentRole: Role, dto: UpgradeEmployeeDto) {
    if (currentRole !== Role.GUEST) {
      throw new ForbiddenException({ code: 'PERMISSION_DENIED', message: 'Only guest accounts can upgrade to employee.' });
    }

    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException({ code: 'USER_NOT_FOUND', message: 'User not found.' });

    if (user.is_employee) {
      throw new ConflictException({ code: 'ALREADY_EMPLOYEE', message: 'Account is already linked to a company.' });
    }

    const roster = await this.prisma.employeeRoster.findFirst({
      where: { employee_id: dto.employee_id, is_active: true },
    });
    if (!roster) {
      throw new ConflictException({ code: 'EMPLOYEE_ID_NOT_FOUND', message: 'Employee ID not found. Contact your HR admin.' });
    }

    if (roster.email.toLowerCase() !== dto.work_email.toLowerCase()) {
      throw new BadRequestException({ code: 'VALIDATION_ERROR', message: 'Work email does not match roster records.' });
    }

    // Step 1 — no OTP yet: send OTP to phone
    if (!dto.otp) {
      await this.otp.sendOtp(user.phone, 'UPGRADE');
      return { message: 'OTP sent to your registered phone. Enter it to complete the upgrade.' };
    }

    // Step 2 — verify OTP and complete upgrade
    await this.otp.verifyOtp(user.phone, dto.otp, 'UPGRADE');

    await this.prisma.guestUpgradeRequest.upsert({
      where: { user_id: userId },
      update: { employee_id: dto.employee_id, work_email: dto.work_email, tenant_id: roster.tenant_id, status: 'PENDING' },
      create: { user_id: userId, employee_id: dto.employee_id, work_email: dto.work_email, tenant_id: roster.tenant_id, status: 'PENDING' },
    });

    const updatedUser = await this.prisma.user.update({
      where: { id: userId },
      data: {
        role: Role.USER,
        tenant_id: roster.tenant_id,
        is_employee: true,
        employee_id: dto.employee_id,
        email: dto.work_email,
      },
    });

    await this.prisma.guestUpgradeRequest.update({
      where: { user_id: userId },
      data: { status: 'COMPLETED', completed_at: new Date() },
    });

    // Revoke old sessions (old JWT has GUEST role, now USER — all tokens invalid)
    await this.revokeAllSessions(userId);

    // Issue new session with updated role/tenant
    const payload = { sub: userId, role: Role.USER, tenant_id: roster.tenant_id, is_employee: true };
    const accessToken = this.tokens.issueAccessToken(payload);
    const refreshToken = this.tokens.issueRefreshToken(payload);
    const expiresAt = new Date(Date.now() + REFRESH_TTL_SECONDS * 1000);

    await this.prisma.session.create({
      data: { user_id: userId, refresh_token: refreshToken, expires_at: expiresAt },
    });

    await this.audit.log({
      userId, tenantId: roster.tenant_id,
      action: AuditAction.PROFILE_UPGRADED,
      module: AuditModule.AUTH,
      metadata: { employee_id: dto.employee_id, tenant_id: roster.tenant_id },
    });

    return {
      access_token: accessToken,
      refresh_token: refreshToken,
      user: {
        id: updatedUser.id,
        role: updatedUser.role,
        tenant_id: updatedUser.tenant_id,
        is_employee: updatedUser.is_employee,
      },
      message: 'Account upgraded. Subsidy and benefits activated.',
    };
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  private async revokeAllSessions(userId: string): Promise<void> {
    const active = await this.prisma.session.findMany({
      where: { user_id: userId, is_revoked: false },
      select: { id: true, refresh_token: true, expires_at: true },
    });
    if (active.length === 0) return;

    await this.prisma.session.updateMany({ where: { user_id: userId, is_revoked: false }, data: { is_revoked: true } });

    for (const s of active) {
      const ttl = Math.max(0, Math.floor((s.expires_at.getTime() - Date.now()) / 1000));
      if (ttl > 0) await this.redis.set(`blacklist:${s.refresh_token}`, '1', ttl);
    }
  }
}
