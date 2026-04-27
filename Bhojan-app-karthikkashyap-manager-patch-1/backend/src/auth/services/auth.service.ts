import {
  Injectable,
<<<<<<< HEAD
  Logger,
=======
>>>>>>> 9164b54b7ae96a96dfb046b32a6f1d92bc55e577
  ConflictException,
  NotFoundException,
  UnauthorizedException,
  ForbiddenException,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';
import { RedisService } from '../../redis/redis.service.js';
import { OtpService } from '../../otp/services/otp.service.js';
import { TokenService } from './jwt.service.js';
import { AuditService } from '../../audit/services/audit.service.js';
import { hashPassword, comparePassword } from '../../common/utils/bcrypt.helper.js';
import { RegisterDto } from '../dto/register.dto.js';
import { LoginDto } from '../dto/login.dto.js';
import { OtpVerifyDto } from '../dto/otp-verify.dto.js';
import { AuditAction, AuditModule, Role, SSOProvider } from '@prisma/client';
<<<<<<< HEAD
import { normalizeIndianPhone } from '../../common/utils/phone.helper.js';
=======
>>>>>>> 9164b54b7ae96a96dfb046b32a6f1d92bc55e577

const LOGIN_ATTEMPTS_TTL = 900; // 15 min
const MAX_LOGIN_ATTEMPTS = 5;
const REFRESH_TTL_SECONDS = 7 * 24 * 60 * 60; // 7 days

interface GoogleSsoInput {
  email: string;
  name: string;
  google_sub: string;
}

@Injectable()
export class AuthService {
<<<<<<< HEAD
  private readonly logger = new Logger(AuthService.name);
=======
>>>>>>> 9164b54b7ae96a96dfb046b32a6f1d92bc55e577
  constructor(
    private prisma: PrismaService,
    private redis: RedisService,
    private otp: OtpService,
    private tokens: TokenService,
    private audit: AuditService,
  ) {}

  // ── EP-01: Register ────────────────────────────────────────────────────────

  async register(dto: RegisterDto, ip?: string) {
<<<<<<< HEAD
    const phone = normalizeIndianPhone(dto.phone);
    this.logger.log(`[DBG-H1] register rawPhone=${dto.phone} normalizedPhone=${phone} userType=${dto.user_type}`);
    // #region agent log
    fetch('http://127.0.0.1:7572/ingest/0165e44f-c140-425a-bb49-5e5c88d4f3e3',{method:'POST',headers:{'Content-Type':'application/json','X-Debug-Session-Id':'2e5b8f'},body:JSON.stringify({sessionId:'2e5b8f',runId:'run1',hypothesisId:'H1',location:'auth.service.ts:register',message:'register normalized phone',data:{rawPhoneLen:(dto.phone??'').length,normalizedPrefix:phone.slice(0,3),normalizedLen:phone.length,userType:dto.user_type},timestamp:Date.now()})}).catch(()=>{});
    // #endregion
    const existing = await this.prisma.user.findFirst({
      where: { OR: [{ phone }, ...(dto.email ? [{ email: dto.email }] : [])] },
=======
    const existing = await this.prisma.user.findFirst({
      where: { OR: [{ phone: dto.phone }, ...(dto.email ? [{ email: dto.email }] : [])] },
>>>>>>> 9164b54b7ae96a96dfb046b32a6f1d92bc55e577
    });
    if (existing) {
      throw new ConflictException({ code: 'USER_ALREADY_EXISTS', message: 'Phone or email already registered.' });
    }

    let tenantId: string | undefined;
    if (dto.user_type === 'EMPLOYEE') {
      const roster = await this.prisma.employeeRoster.findFirst({
        where: { employee_id: dto.employee_id, is_active: true },
      });
      if (!roster) {
        throw new ConflictException({ code: 'EMPLOYEE_ID_NOT_FOUND', message: 'Employee ID not found. Contact your HR admin.' });
      }
      tenantId = roster.tenant_id;
    }

    const passwordHash = await hashPassword(dto.password);
    const pending = { full_name: dto.full_name, password_hash: passwordHash, user_type: dto.user_type,
      ...(dto.email && { email: dto.email }), ...(dto.employee_id && { employee_id: dto.employee_id }),
      ...(tenantId && { tenant_id: tenantId }) };

<<<<<<< HEAD
    await this.redis.set(`reg_pending:${phone}`, JSON.stringify(pending), 600);
    await this.otp.sendOtp(phone, 'REGISTRATION');

    await this.audit.log({ action: AuditAction.OTP_REQUESTED, module: AuditModule.AUTH, ipAddress: ip,
      metadata: { phone, user_type: dto.user_type } });

    return { otp_reference: `ref-${phone}-${Date.now()}`, expires_in: 300 };
=======
    await this.redis.set(`reg_pending:${dto.phone}`, JSON.stringify(pending), 600);
    await this.otp.sendOtp(dto.phone, 'REGISTRATION');

    await this.audit.log({ action: AuditAction.OTP_REQUESTED, module: AuditModule.AUTH, ipAddress: ip,
      metadata: { phone: dto.phone, user_type: dto.user_type } });

    return { otp_reference: `ref-${dto.phone}-${Date.now()}`, expires_in: 300 };
>>>>>>> 9164b54b7ae96a96dfb046b32a6f1d92bc55e577
  }

  // ── EP-02: OTP Verify (Registration + Login) ──────────────────────────────

  async verifyOtp(dto: OtpVerifyDto, ip?: string, device?: string) {
<<<<<<< HEAD
    const phone = normalizeIndianPhone(dto.phone);
    const pendingRaw = await this.redis.get(`reg_pending:${phone}`);
    this.logger.log(`[DBG-H2] verifyOtp phone=${phone} hasPending=${!!pendingRaw}`);
    // #region agent log
    fetch('http://127.0.0.1:7572/ingest/0165e44f-c140-425a-bb49-5e5c88d4f3e3',{method:'POST',headers:{'Content-Type':'application/json','X-Debug-Session-Id':'2e5b8f'},body:JSON.stringify({sessionId:'2e5b8f',runId:'run1',hypothesisId:'H2',location:'auth.service.ts:verifyOtp',message:'verifyOtp route selection',data:{normalizedPrefix:phone.slice(0,3),normalizedLen:phone.length,hasPending:!!pendingRaw},timestamp:Date.now()})}).catch(()=>{});
    // #endregion

    if (pendingRaw) {
      const existingUser = await this.prisma.user.findFirst({
        where: { phone },
        select: { id: true },
      });
      this.logger.log(`[DBG-H2] pendingBranch phone=${phone} hasExistingUser=${!!existingUser}`);
      // #region agent log
      fetch('http://127.0.0.1:7572/ingest/0165e44f-c140-425a-bb49-5e5c88d4f3e3',{method:'POST',headers:{'Content-Type':'application/json','X-Debug-Session-Id':'2e5b8f'},body:JSON.stringify({sessionId:'2e5b8f',runId:'run1',hypothesisId:'H2',location:'auth.service.ts:verifyOtp',message:'verifyOtp pending+user check',data:{hasExistingUser:!!existingUser,branch:existingUser?'force_login':'complete_registration'},timestamp:Date.now()})}).catch(()=>{});
      // #endregion
      if (existingUser) {
        // Stale registration cache should not block login OTP flow.
        await this.redis.del(`reg_pending:${phone}`);
      } else {
      return this.completeRegistration(phone, dto.otp, JSON.parse(pendingRaw), ip, device);
      }
    }
    return this.otpLogin(phone, dto.otp, ip, device);
=======
    const pendingRaw = await this.redis.get(`reg_pending:${dto.phone}`);

    if (pendingRaw) {
      return this.completeRegistration(dto.phone, dto.otp, JSON.parse(pendingRaw), ip, device);
    }
    return this.otpLogin(dto.phone, dto.otp, ip, device);
>>>>>>> 9164b54b7ae96a96dfb046b32a6f1d92bc55e577
  }

  private async completeRegistration(
    phone: string, submittedOtp: string, pending: Record<string, string>, ip?: string, device?: string,
  ) {
    await this.otp.verifyOtp(phone, submittedOtp, 'REGISTRATION');

    const isEmployee = pending['user_type'] === 'EMPLOYEE';
    const user = await this.prisma.user.create({
      data: {
        phone,
        full_name: pending['full_name'],
        password_hash: pending['password_hash'],
        role: isEmployee ? Role.USER : Role.GUEST,
        tenant_id: pending['tenant_id'] ?? null,
        email: pending['email'] ?? null,
        employee_id: pending['employee_id'] ?? null,
        is_employee: isEmployee,
        is_verified: true,
        is_active: true,
      },
    });

    await this.redis.del(`reg_pending:${phone}`);

    const { accessToken, refreshToken } = await this.createSession(user.id, user.role, user.tenant_id, user.is_employee, ip, device);

    await this.audit.log({ userId: user.id, tenantId: user.tenant_id ?? undefined,
      action: isEmployee ? AuditAction.USER_REGISTER : AuditAction.GUEST_REGISTER,
      module: AuditModule.AUTH, ipAddress: ip, device });

    return { access_token: accessToken, refresh_token: refreshToken, user: this.userShape(user) };
  }

  private async otpLogin(phone: string, submittedOtp: string, ip?: string, device?: string) {
    const user = await this.findActiveUser({ phone });

    await this.otp.verifyOtp(phone, submittedOtp);

    const { accessToken, refreshToken } = await this.createSession(user.id, user.role, user.tenant_id, user.is_employee, ip, device);
    await this.prisma.user.update({ where: { id: user.id }, data: { last_login_at: new Date() } });

    await this.audit.log({ userId: user.id, tenantId: user.tenant_id ?? undefined,
      action: AuditAction.USER_LOGIN, module: AuditModule.AUTH, ipAddress: ip, device });

    return { access_token: accessToken, refresh_token: refreshToken, user: this.userShape(user) };
  }

<<<<<<< HEAD
  // ── EP-03: Login OTP Request ───────────────────────────────────────────────

  async requestLoginOtp(phone: string, ip?: string) {
    phone = normalizeIndianPhone(phone);
    this.logger.log(`[DBG-H3] requestLoginOtp phone=${phone}`);
    // #region agent log
    fetch('http://127.0.0.1:7572/ingest/0165e44f-c140-425a-bb49-5e5c88d4f3e3',{method:'POST',headers:{'Content-Type':'application/json','X-Debug-Session-Id':'2e5b8f'},body:JSON.stringify({sessionId:'2e5b8f',runId:'run1',hypothesisId:'H3',location:'auth.service.ts:requestLoginOtp',message:'requestLoginOtp normalized',data:{normalizedPrefix:phone.slice(0,3),normalizedLen:phone.length},timestamp:Date.now()})}).catch(()=>{});
    // #endregion
    const user = await this.findActiveUser({ phone });
    await this.otp.sendOtp(phone, 'LOGIN');
    await this.audit.log({
      userId: user.id,
      tenantId: user.tenant_id ?? undefined,
      action: AuditAction.OTP_REQUESTED,
      module: AuditModule.AUTH,
      ipAddress: ip,
      metadata: { phone, context: 'LOGIN' },
    });
    return { otp_reference: '', message: 'OTP sent successfully.' };
  }

  // ── EP-04: Password Login ──────────────────────────────────────────────────

  async loginPassword(dto: LoginDto, ip?: string, device?: string) {
    const normalizedPhone = normalizeIndianPhone(dto.phone);
    const user = await this.findActiveUser({ phone: normalizedPhone });

    const attemptsKey = `login_attempts:${normalizedPhone}`;
=======
  // ── EP-03: Password Login ──────────────────────────────────────────────────

  async loginPassword(dto: LoginDto, ip?: string, device?: string) {
    const user = await this.findActiveUser({ phone: dto.phone });

    const attemptsKey = `login_attempts:${dto.phone}`;
>>>>>>> 9164b54b7ae96a96dfb046b32a6f1d92bc55e577
    const attempts = parseInt((await this.redis.get(attemptsKey)) ?? '0', 10);
    if (attempts >= MAX_LOGIN_ATTEMPTS) {
      throw new HttpException({ code: 'ACCOUNT_LOCKED', message: 'Account locked — too many failed attempts. Try again in 15 minutes.' }, HttpStatus.TOO_MANY_REQUESTS);
    }

    const valid = await comparePassword(dto.password, user.password_hash ?? '');
    if (!valid) {
      const newCount = await this.redis.incr(attemptsKey);
      if (newCount === 1) await this.redis.expire(attemptsKey, LOGIN_ATTEMPTS_TTL);

      await this.audit.log({ userId: user.id, action: AuditAction.AUTH_LOGIN_FAILED,
        module: AuditModule.AUTH, ipAddress: ip, metadata: { attempt_count: newCount } });

      const remaining = MAX_LOGIN_ATTEMPTS - newCount;
      throw new UnauthorizedException({
        code: 'AUTH_LOGIN_FAILED',
        message: remaining > 0 ? `Incorrect password. ${remaining} attempt${remaining === 1 ? '' : 's'} remaining.` : 'Incorrect password.',
      });
    }

    await this.redis.del(attemptsKey);
    const { accessToken, refreshToken } = await this.createSession(user.id, user.role, user.tenant_id, user.is_employee, ip, device);
    await this.prisma.user.update({ where: { id: user.id }, data: { last_login_at: new Date() } });

    await this.audit.log({ userId: user.id, tenantId: user.tenant_id ?? undefined,
      action: AuditAction.USER_LOGIN, module: AuditModule.AUTH, ipAddress: ip, device });

    return { access_token: accessToken, refresh_token: refreshToken, user: this.userShape(user) };
  }

  // ── EP-04: Token Refresh ───────────────────────────────────────────────────

  async refreshToken(refreshToken: string) {
    const session = await this.prisma.session.findUnique({ where: { refresh_token: refreshToken } });

    if (!session || session.is_revoked) {
      throw new UnauthorizedException({ code: 'REFRESH_TOKEN_INVALID', message: 'Session not found or already revoked.' });
    }
    if (new Date() > session.expires_at) {
      throw new UnauthorizedException({ code: 'REFRESH_TOKEN_INVALID', message: 'Refresh token expired.' });
    }

    const user = await this.findActiveUser({ id: session.user_id });

    // Rotate — revoke old session and blacklist
    await this.prisma.session.update({ where: { id: session.id }, data: { is_revoked: true } });
    await this.redis.set(`blacklist:${refreshToken}`, '1', REFRESH_TTL_SECONDS);

    const { accessToken, refreshToken: newRefreshToken } = await this.createSession(user.id, user.role, user.tenant_id, user.is_employee);

    await this.audit.log({ userId: user.id, action: AuditAction.TOKEN_REFRESH, module: AuditModule.SESSION });

    return { access_token: accessToken, refresh_token: newRefreshToken };
  }

  // ── EP-05: Logout ──────────────────────────────────────────────────────────

  async logout(userId: string, accessToken: string, refreshToken: string) {
    const session = await this.prisma.session.findFirst({
      where: { refresh_token: refreshToken, user_id: userId },
    });

    if (session) {
      await this.prisma.session.update({ where: { id: session.id }, data: { is_revoked: true } });
    }

    const accessTtl = 900; // 15 min max
    await this.redis.set(`blacklist:${accessToken}`, '1', accessTtl);
    await this.redis.set(`blacklist:${refreshToken}`, '1', REFRESH_TTL_SECONDS);

    await this.audit.log({ userId, action: AuditAction.USER_LOGOUT, module: AuditModule.SESSION });
  }

  // ── EP-06: Get Profile ─────────────────────────────────────────────────────

  async getProfile(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { profile: true },
    });
    if (!user) throw new NotFoundException({ code: 'USER_NOT_FOUND', message: 'User not found.' });

    return {
      user: {
        id: user.id, phone: user.phone, email: user.email, full_name: user.full_name,
        role: user.role, tenant_id: user.tenant_id, is_employee: user.is_employee,
        employee_id: user.employee_id, last_login_at: user.last_login_at,
      },
      profile: {
        avatar_url: user.profile?.avatar_url ?? null,
        department: user.profile?.department ?? null,
        floor: user.profile?.floor ?? null,
        building: user.profile?.building ?? null,
        preferences: user.profile?.preferences ?? null,
      },
    };
  }

  // ── EP-16: Google SSO Callback ──────────────────────────────────────────────

  async loginWithGoogle(google: GoogleSsoInput, ip?: string, device?: string) {
    const email = google.email.toLowerCase();
    const atIndex = email.lastIndexOf('@');
    const domain = atIndex > -1 ? email.slice(atIndex + 1) : '';

    const tenant = await this.prisma.tenant.findFirst({
      where: { domain, is_active: true },
      select: { id: true, domain: true },
    });
    if (!tenant) {
      throw new ForbiddenException({ code: 'SSO_DOMAIN_MISMATCH', message: 'Email domain is not allowed for SSO.' });
    }

    let user = await this.prisma.user.findFirst({ where: { email } });
    if (!user) {
      user = await this.prisma.user.create({
        data: {
          phone: await this.generateSsoPhone(),
          email,
          full_name: google.name,
          role: Role.USER,
          tenant_id: tenant.id,
          is_employee: true,
          is_verified: true,
          is_active: true,
          sso_provider: SSOProvider.GOOGLE,
          sso_provider_id: google.google_sub,
        },
      });
    } else {
      if (!user.is_active) {
        throw new ForbiddenException({ code: 'ACCOUNT_DEACTIVATED', message: 'Account deactivated.' });
      }
      if (user.is_suspended) {
        throw new ForbiddenException({ code: 'ACCOUNT_SUSPENDED', message: 'Account suspended. Contact support.' });
      }
      if (user.is_deleted) {
        throw new ForbiddenException({ code: 'ACCOUNT_DELETED', message: 'This account no longer exists.' });
      }
      if (user.tenant_id && user.tenant_id !== tenant.id) {
        throw new ForbiddenException({ code: 'TENANT_MISMATCH', message: 'User is linked to a different tenant.' });
      }

      const updatedUser = await this.prisma.user.update({
        where: { id: user.id },
        data: {
          full_name: user.full_name || google.name,
          tenant_id: user.tenant_id ?? tenant.id,
          is_employee: true,
          is_verified: true,
          sso_provider: SSOProvider.GOOGLE,
          sso_provider_id: google.google_sub,
        },
      });
      user = { ...user, ...updatedUser };
    }

    const { accessToken, refreshToken } = await this.createSession(
      user.id,
      user.role,
      user.tenant_id,
      user.is_employee,
      ip,
      device,
    );
    await this.prisma.user.update({ where: { id: user.id }, data: { last_login_at: new Date() } });

    await this.audit.log({
      userId: user.id,
      tenantId: user.tenant_id ?? undefined,
      action: AuditAction.SSO_LOGIN,
      module: AuditModule.AUTH,
      ipAddress: ip,
      device,
      metadata: { provider: 'GOOGLE' },
    });

    return {
      access_token: accessToken,
      refresh_token: refreshToken,
      user: {
        id: user.id,
        email: user.email,
        role: user.role,
        tenant_id: user.tenant_id,
        is_employee: user.is_employee,
      },
    };
  }

  // ── Shared helpers ─────────────────────────────────────────────────────────

  private async findActiveUser(where: { id?: string; phone?: string; email?: string }) {
    const user = await this.prisma.user.findFirst({ where });
    if (!user) throw new NotFoundException({ code: 'USER_NOT_FOUND', message: 'No account found.' });
    if (!user.is_active) throw new ForbiddenException({ code: 'ACCOUNT_DEACTIVATED', message: 'Account deactivated.' });
    if (user.is_suspended) throw new ForbiddenException({ code: 'ACCOUNT_SUSPENDED', message: 'Account suspended. Contact support.' });
    if (user.is_deleted) throw new ForbiddenException({ code: 'ACCOUNT_DELETED', message: 'This account no longer exists.' });
    return user;
  }

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

  private userShape(user: { id: string; phone: string; full_name: string; role: Role; tenant_id: string | null; is_employee: boolean; is_verified: boolean; employee_id: string | null }) {
    return {
      id: user.id, phone: user.phone, full_name: user.full_name,
      role: user.role, tenant_id: user.tenant_id, is_employee: user.is_employee,
      is_verified: user.is_verified, employee_id: user.employee_id,
    };
  }

  private async generateSsoPhone(): Promise<string> {
    // SSO users may not provide phone; generate deterministic-format synthetic phone.
    for (let i = 0; i < 10; i += 1) {
      const suffix = `${Date.now().toString().slice(-8)}${i}`.slice(0, 9);
      const phone = `+919${suffix}`;
      const exists = await this.prisma.user.findFirst({ where: { phone }, select: { id: true } });
      if (!exists) return phone;
    }
    throw new HttpException(
      { code: 'SSO_PROVIDER_ERROR', message: 'Unable to create a unique SSO phone identifier.' },
      HttpStatus.BAD_GATEWAY,
    );
  }
}
