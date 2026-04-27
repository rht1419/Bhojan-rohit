import {
  Injectable,
  UnauthorizedException,
  NotFoundException,
  ForbiddenException,
<<<<<<< HEAD
  ConflictException,
=======
>>>>>>> 9164b54b7ae96a96dfb046b32a6f1d92bc55e577
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';
import { RedisService } from '../../redis/redis.service.js';
import { TokenService } from '../../auth/services/jwt.service.js';
<<<<<<< HEAD
import { OtpService } from '../../otp/services/otp.service.js';
=======
>>>>>>> 9164b54b7ae96a96dfb046b32a6f1d92bc55e577
import { AuditService } from '../../audit/services/audit.service.js';
import { hashPassword, comparePassword } from '../../common/utils/bcrypt.helper.js';
import { VendorActivateDto } from '../dto/vendor-activate.dto.js';
import { VendorLoginDto } from '../dto/vendor-login.dto.js';
import { VendorProfileUpdateDto } from '../dto/vendor-profile-update.dto.js';
<<<<<<< HEAD
import { VendorSelfRegisterDto } from '../dto/vendor-self-register.dto.js';
import { VendorRequestOtpDto } from '../dto/vendor-request-otp.dto.js';
import { VendorVerifyOtpDto } from '../dto/vendor-verify-otp.dto.js';
=======
>>>>>>> 9164b54b7ae96a96dfb046b32a6f1d92bc55e577
import { AuditAction, AuditModule, Role } from '@prisma/client';

const LOGIN_ATTEMPTS_TTL = 900;
const MAX_LOGIN_ATTEMPTS = 5;
const REFRESH_TTL_SECONDS = 7 * 24 * 60 * 60;

@Injectable()
export class VendorService {
  private readonly logger = new Logger(VendorService.name);

  constructor(
    private prisma: PrismaService,
    private redis: RedisService,
    private tokens: TokenService,
<<<<<<< HEAD
    private otp: OtpService,
    private audit: AuditService,
  ) {}

  // ── Self-Registration: POST /vendor/auth/register ─────────────────────────

  async selfRegister(dto: VendorSelfRegisterDto) {
    const existing = await this.prisma.user.findFirst({
      where: { OR: [{ phone: dto.phone }, { email: dto.email }] },
    });
    if (existing) {
      throw new ConflictException({ code: 'USER_ALREADY_EXISTS', message: 'Phone or email already registered.' });
    }

    const user = await this.prisma.user.create({
      data: {
        phone: dto.phone,
        email: dto.email,
        full_name: dto.business_name,
        role: Role.VENDOR,
        is_active: false,
        is_verified: false,
        is_employee: false,
        vendor_profile: {
          create: {
            business_name: dto.business_name,
            category: dto.category,
          },
        },
      },
    });

    await this.otp.sendOtp(dto.phone, 'VENDOR_REGISTER');

    await this.audit.log({ userId: user.id, action: AuditAction.VENDOR_REGISTER, module: AuditModule.AUTH });

    return { message: 'OTP sent to your phone.' };
  }

  // ── Self-Registration: POST /vendor/auth/request-otp ──────────────────────

  async requestRegistrationOtp(dto: VendorRequestOtpDto) {
    const user = await this.prisma.user.findFirst({
      where: { phone: dto.phone, role: Role.VENDOR, is_active: false },
    });
    if (!user) {
      throw new NotFoundException({ code: 'USER_NOT_FOUND', message: 'No pending registration found for this phone.' });
    }

    await this.otp.sendOtp(dto.phone, 'VENDOR_REGISTER');

    return { message: 'OTP resent.' };
  }

  // ── Self-Registration: POST /vendor/auth/verify-otp ───────────────────────

  async verifyRegistrationOtp(dto: VendorVerifyOtpDto, ip?: string, device?: string) {
    const user = await this.prisma.user.findFirst({
      where: { phone: dto.phone, role: Role.VENDOR, is_active: false },
    });
    if (!user) {
      throw new NotFoundException({ code: 'USER_NOT_FOUND', message: 'No pending registration found for this phone.' });
    }

    await this.otp.verifyOtp(dto.phone, dto.otp, 'VENDOR_REGISTER');

    const { accessToken, refreshToken } = await this.createSession(
      user.id, user.role, user.tenant_id, user.is_employee, ip, device,
    );

    await this.audit.log({ userId: user.id, action: AuditAction.VENDOR_LOGIN, module: AuditModule.AUTH, ipAddress: ip });

    return {
      access_token: accessToken,
      refresh_token: refreshToken,
      user: { id: user.id, phone: user.phone, role: user.role, tenant_id: user.tenant_id, is_verified: false },
    };
  }

=======
    private audit: AuditService,
  ) {}

>>>>>>> 9164b54b7ae96a96dfb046b32a6f1d92bc55e577
  // ── EP-17: Vendor Activate ─────────────────────────────────────────────────

  async activate(dto: VendorActivateDto) {
    const userId = await this.redis.get(`activation:${dto.activation_token}`);
    if (!userId) {
      throw new UnauthorizedException({ code: 'UNAUTHORIZED', message: 'Activation token is invalid or has expired.' });
    }

    const user = await this.prisma.user.findFirst({ where: { id: userId, role: Role.VENDOR } });
    if (!user) {
      throw new UnauthorizedException({ code: 'UNAUTHORIZED', message: 'Activation token is invalid.' });
    }

    const passwordHash = await hashPassword(dto.password);

    await this.prisma.user.update({
      where: { id: userId },
      data: { password_hash: passwordHash, is_verified: true, is_active: true },
    });

    await this.redis.del(`activation:${dto.activation_token}`);

    await this.audit.log({ userId, action: AuditAction.VENDOR_ACTIVATED, module: AuditModule.AUTH });
    await this.audit.log({ userId, action: AuditAction.EMAIL_VERIFIED, module: AuditModule.AUTH });

    return { message: 'Account activated. Please log in.' };
  }

  // ── EP-18: Vendor Login ────────────────────────────────────────────────────

  async login(dto: VendorLoginDto, ip?: string, device?: string) {
    const user = await this.prisma.user.findFirst({ where: { phone: dto.phone, role: Role.VENDOR } });
    if (!user) {
      throw new NotFoundException({ code: 'USER_NOT_FOUND', message: 'No account found.' });
    }

    if (!user.is_verified) {
      throw new ForbiddenException({ code: 'EMAIL_NOT_VERIFIED', message: 'Account not activated. Check your email for the activation link.' });
    }
    if (!user.is_active) {
      throw new ForbiddenException({ code: 'ACCOUNT_DEACTIVATED', message: 'Account deactivated.' });
    }
    if (user.is_suspended) {
      throw new ForbiddenException({ code: 'ACCOUNT_SUSPENDED', message: 'Account suspended. Contact support.' });
    }
    if (user.is_deleted) {
      throw new ForbiddenException({ code: 'ACCOUNT_DELETED', message: 'This account no longer exists.' });
    }

    const attemptsKey = `login_attempts:${dto.phone}`;
    const attempts = parseInt((await this.redis.get(attemptsKey)) ?? '0', 10);
    if (attempts >= MAX_LOGIN_ATTEMPTS) {
      throw new HttpException(
        { code: 'ACCOUNT_LOCKED', message: 'Account locked — too many failed attempts. Try again in 15 minutes.' },
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    const valid = await comparePassword(dto.password, user.password_hash ?? '');
    if (!valid) {
      const newCount = await this.redis.incr(attemptsKey);
      if (newCount === 1) await this.redis.expire(attemptsKey, LOGIN_ATTEMPTS_TTL);
      await this.audit.log({
        userId: user.id, action: AuditAction.AUTH_LOGIN_FAILED,
        module: AuditModule.AUTH, ipAddress: ip, metadata: { attempt_count: newCount },
      });
      throw new UnauthorizedException({ code: 'AUTH_LOGIN_FAILED', message: 'Incorrect password.' });
    }

    await this.redis.del(attemptsKey);

    const { accessToken, refreshToken } = await this.createSession(
      user.id, user.role, user.tenant_id, user.is_employee, ip, device,
    );
    await this.prisma.user.update({ where: { id: user.id }, data: { last_login_at: new Date() } });

    await this.audit.log({
      userId: user.id, tenantId: user.tenant_id ?? undefined,
      action: AuditAction.VENDOR_LOGIN, module: AuditModule.AUTH, ipAddress: ip, device,
    });

    return {
      access_token: accessToken,
      refresh_token: refreshToken,
      user: { id: user.id, phone: user.phone, role: user.role, tenant_id: user.tenant_id, is_verified: user.is_verified },
    };
  }

  // ── EP-19: Vendor Profile Update ───────────────────────────────────────────

  async updateProfile(userId: string, dto: VendorProfileUpdateDto) {
    const vendor = await this.prisma.user.findFirst({ where: { id: userId, role: Role.VENDOR } });
    if (!vendor) {
      throw new NotFoundException({ code: 'USER_NOT_FOUND', message: 'Vendor account not found.' });
    }
    if (!vendor.is_active) {
      throw new ForbiddenException({ code: 'ACCOUNT_DEACTIVATED', message: 'Account deactivated.' });
    }
    if (vendor.is_suspended) {
      throw new ForbiddenException({ code: 'ACCOUNT_SUSPENDED', message: 'Account suspended. Contact support.' });
    }
    if (vendor.is_deleted) {
      throw new ForbiddenException({ code: 'ACCOUNT_DELETED', message: 'This account no longer exists.' });
    }

    const existingProfile = await this.prisma.vendorProfile.findUnique({ where: { user_id: userId } });
    if (!existingProfile) {
      throw new NotFoundException({ code: 'USER_NOT_FOUND', message: 'Vendor profile not found.' });
    }

    const updateData = {
      ...(dto.business_name !== undefined && { business_name: dto.business_name }),
      ...(dto.business_address !== undefined && { business_address: dto.business_address }),
      ...(dto.city !== undefined && { city: dto.city }),
      ...(dto.logo_url !== undefined && { logo_url: dto.logo_url }),
      ...(dto.fssai_number !== undefined && { fssai_number: dto.fssai_number }),
    };

    const vendor_profile = Object.keys(updateData).length === 0
      ? existingProfile
      : await this.prisma.vendorProfile.update({
        where: { user_id: userId },
        data: updateData,
      });

    await this.audit.log({
      userId,
      action: AuditAction.PROFILE_UPDATED,
      module: AuditModule.VENDOR,
    });

    return { vendor_profile };
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
