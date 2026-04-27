import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  Logger,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';
import { RedisService } from '../../redis/redis.service.js';
import { OtpService } from '../../otp/services/otp.service.js';
import { TokenService } from '../../auth/services/jwt.service.js';
import { AuditService } from '../../audit/services/audit.service.js';
import { AdminLoginDto } from '../dto/admin-login.dto.js';
import { AuditAction, AuditModule, Role } from '@prisma/client';

const ADMIN_ROLES = [Role.SUPER_ADMIN, Role.OPS_ADMIN, Role.TECH_ADMIN];
const REFRESH_TTL_SECONDS = 7 * 24 * 60 * 60;

@Injectable()
export class AdminAuthService {
  private readonly logger = new Logger(AdminAuthService.name);

  constructor(
    private prisma: PrismaService,
    private redis: RedisService,
    private otp: OtpService,
    private tokens: TokenService,
    private audit: AuditService,
  ) {}

  // ── EP-20: Admin Login (two-step via single endpoint) ─────────────────────
  // Step 1: body has only email     → look up admin, send OTP to email
  // Step 2: body has email + otp    → verify OTP, issue tokens

  async login(dto: AdminLoginDto, ip?: string, device?: string) {
    const user = await this.prisma.user.findFirst({
      where: { email: dto.email, role: { in: ADMIN_ROLES } },
    });
    if (!user) {
      throw new NotFoundException({ code: 'USER_NOT_FOUND', message: 'No admin account found with this email.' });
    }
    if (!user.is_active) {
      throw new ForbiddenException({ code: 'ACCOUNT_DEACTIVATED', message: 'Account deactivated.' });
    }
    if (user.is_deleted) {
      throw new ForbiddenException({ code: 'ACCOUNT_DELETED', message: 'This account no longer exists.' });
    }

    // Step 1 — no OTP yet: send OTP to email
    if (!dto.otp) {
      await this.otp.sendEmailOtp(user.email!);
      await this.audit.log({
        userId: user.id, action: AuditAction.OTP_REQUESTED,
        module: AuditModule.AUTH, ipAddress: ip, metadata: { email: user.email },
      });
      return { message: 'OTP sent to your email. Valid for 5 minutes.' };
    }

    // Step 2 — OTP provided: verify and issue tokens
    await this.otp.verifyOtp(user.email!, dto.otp, 'ADMIN_LOGIN');

    const { accessToken, refreshToken } = await this.createSession(
      user.id, user.role, user.tenant_id, user.is_employee, ip, device,
    );
    await this.prisma.user.update({ where: { id: user.id }, data: { last_login_at: new Date() } });

    await this.audit.log({
      userId: user.id, tenantId: user.tenant_id ?? undefined,
      action: AuditAction.ADMIN_LOGIN, module: AuditModule.AUTH, ipAddress: ip, device,
    });

    return {
      access_token: accessToken,
      refresh_token: refreshToken,
      user: { id: user.id, email: user.email, role: user.role, tenant_id: user.tenant_id },
    };
  }

  // ── EP-21: Admin Permissions ───────────────────────────────────────────────

  async getPermissions(userId: string, role: Role) {
    const permissions = await this.prisma.rolePermission.findMany({
      where: { role },
      select: { module: true, can_create: true, can_read: true, can_update: true, can_delete: true },
      orderBy: { module: 'asc' },
    });

    // Check Redis for active delegations: delegate:{userId}:{module}
    const delegationKeys = await this.redis.keys(`delegate:${userId}:*`);
    const delegations: { module: string; expires_at: string }[] = [];

    for (const key of delegationKeys) {
      const raw = await this.redis.get(key);
      if (raw) {
        const module = key.split(':')[2];
        const { expires_at } = JSON.parse(raw) as { expires_at: string };
        delegations.push({ module, expires_at });
      }
    }

    return { role, permissions, delegations };
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  private async createSession(
    userId: string, role: Role, tenantId: string | null, isEmployee: boolean, ip?: string, device?: string,
  ) {
    const payload = { sub: userId, role, tenant_id: tenantId, is_employee: isEmployee };
    const accessToken = this.tokens.issueAccessToken(payload);
    const refreshToken = this.tokens.issueRefreshToken(payload);

    const expiresAt = new Date(Date.now() + REFRESH_TTL_SECONDS * 1000);
    await this.prisma.session.create({
      data: { user_id: userId, refresh_token: refreshToken, ip_address: ip, device, expires_at: expiresAt },
    });

    return { accessToken, refreshToken };
  }
}
