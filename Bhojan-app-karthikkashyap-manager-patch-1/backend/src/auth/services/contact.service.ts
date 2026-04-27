import {
  Injectable,
  ConflictException,
  BadRequestException,
  NotFoundException,
  ForbiddenException,
  Logger,
} from '@nestjs/common';
import { randomUUID } from 'crypto';
import { PrismaService } from '../../prisma/prisma.service.js';
import { RedisService } from '../../redis/redis.service.js';
import { TokenService } from './jwt.service.js';
import { AuditService } from '../../audit/services/audit.service.js';
import type { ContactChangeDto } from '../dto/contact-change.dto.js';
import type { ContactVerifyDto } from '../dto/contact-verify.dto.js';
import { AuditAction, AuditModule, ContactType, Role } from '@prisma/client';

const OTP_TTL = 300;
const REFRESH_TTL_SECONDS = 7 * 24 * 60 * 60;

@Injectable()
export class ContactService {
  private readonly logger = new Logger(ContactService.name);

  constructor(
    private prisma: PrismaService,
    private redis: RedisService,
    private tokens: TokenService,
    private audit: AuditService,
  ) {}

  // ── EP-11: Contact Change Init ─────────────────────────────────────────────

  async initiateChange(userId: string, dto: ContactChangeDto) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException({ code: 'USER_NOT_FOUND', message: 'User not found.' });

    this.validateContactFormat(dto.type, dto.new_value);

    // Check new_value not already taken
    const duplicate = await this.prisma.user.findFirst({
      where: dto.type === ContactType.EMAIL ? { email: dto.new_value } : { phone: dto.new_value },
    });
    if (duplicate) {
      throw new ConflictException({ code: 'USER_ALREADY_EXISTS', message: 'This contact is already registered.' });
    }

    const oldValue = dto.type === ContactType.EMAIL ? (user.email ?? '') : user.phone;

    const request = await this.prisma.contactChangeRequest.create({
      data: {
        user_id: userId,
        type: dto.type,
        old_value: oldValue,
        new_value: dto.new_value,
        status: 'PENDING',
      },
    });

    // Generate OTPs for old and new contacts
    const otpOld = this.generateOtp();
    const otpNew = this.generateOtp();

    await Promise.all([
      this.redis.set(`otp_old:${request.id}`, otpOld, OTP_TTL),
      this.redis.set(`otp_new:${request.id}`, otpNew, OTP_TTL),
    ]);

    // Log OTPs to console (TODO: send via SMS/SMTP in production)
    if (dto.type === ContactType.EMAIL) {
      this.logger.log(`[CONTACT-OTP-OLD] phone=${user.phone} otp=${otpOld}`);
      this.logger.log(`[CONTACT-OTP-NEW] email=${dto.new_value} otp=${otpNew}`);
    } else {
      this.logger.log(`[CONTACT-OTP-OLD] phone=${oldValue} otp=${otpOld}`);
      this.logger.log(`[CONTACT-OTP-NEW] phone=${dto.new_value} otp=${otpNew}`);
    }

    await this.audit.log({ userId, action: AuditAction.OTP_REQUESTED, module: AuditModule.AUTH, metadata: { type: dto.type } });

    return { request_id: request.id, message: 'OTP sent to both current and new contact' };
  }

  // ── EP-12: Contact Change Verify ──────────────────────────────────────────

  async verifyChange(userId: string, dto: ContactVerifyDto) {
    const request = await this.prisma.contactChangeRequest.findFirst({
      where: { id: dto.request_id, user_id: userId, status: 'PENDING' },
    });
    if (!request) {
      throw new NotFoundException({ code: 'REQUEST_NOT_FOUND', message: 'Contact change request not found or expired.' });
    }

    const [storedOld, storedNew] = await Promise.all([
      this.redis.get(`otp_old:${request.id}`),
      this.redis.get(`otp_new:${request.id}`),
    ]);

    if (!storedOld || !storedNew) {
      throw new BadRequestException({ code: 'OTP_EXPIRED', message: 'OTPs have expired. Please restart the process.' });
    }
    if (storedOld !== dto.otp_old || storedNew !== dto.otp_new) {
      throw new BadRequestException({ code: 'OTP_INVALID', message: 'One or both OTPs are incorrect.' });
    }

    // Both OTPs correct — apply the change
    const updateData = request.type === ContactType.EMAIL
      ? { email: request.new_value }
      : { phone: request.new_value };

    const user = await this.prisma.user.update({
      where: { id: userId },
      data: updateData,
    });

    await this.prisma.contactChangeRequest.update({
      where: { id: request.id },
      data: { status: 'COMPLETED', otp_verified: true, completed_at: new Date() },
    });

    await Promise.all([
      this.redis.del(`otp_old:${request.id}`, `otp_new:${request.id}`),
    ]);

    // Revoke all old sessions
    await this.revokeAllSessions(userId);

    // Issue new session
    const payload = { sub: userId, role: user.role, tenant_id: user.tenant_id, is_employee: user.is_employee };
    const accessToken = this.tokens.issueAccessToken(payload);
    const refreshToken = this.tokens.issueRefreshToken(payload);
    const expiresAt = new Date(Date.now() + REFRESH_TTL_SECONDS * 1000);

    await this.prisma.session.create({
      data: { user_id: userId, refresh_token: refreshToken, expires_at: expiresAt },
    });

    const action = request.type === ContactType.EMAIL ? AuditAction.EMAIL_CHANGED : AuditAction.PHONE_CHANGED;
    await this.audit.log({ userId, action, module: AuditModule.AUTH });

    return { access_token: accessToken, refresh_token: refreshToken, message: 'Contact updated. All sessions revoked.' };
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  private validateContactFormat(type: ContactType, value: string): void {
    if (type === ContactType.EMAIL) {
      if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)) {
        throw new BadRequestException({ code: 'VALIDATION_ERROR', message: 'Invalid email format.' });
      }
    } else {
      if (!/^\+91[6-9]\d{9}$/.test(value)) {
        throw new BadRequestException({ code: 'VALIDATION_ERROR', message: 'Phone must be a valid Indian mobile number (+91XXXXXXXXXX).' });
      }
    }
  }

  private generateOtp(): string {
    return Math.floor(100000 + Math.random() * 900000).toString();
  }

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
