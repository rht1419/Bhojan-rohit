import { ForbiddenException } from '@nestjs/common';
import { AuditAction, AuditModule, Role } from '@prisma/client';
import { AuthService } from './auth.service';

describe('AuthService (EP-15/EP-16 Google SSO)', () => {
  const makeService = () => {
    const prisma = {
      user: { findFirst: jest.fn(), create: jest.fn(), update: jest.fn() },
      tenant: { findFirst: jest.fn() },
      session: { create: jest.fn() },
      employeeRoster: { findFirst: jest.fn() },
    };
    const redis = { get: jest.fn(), set: jest.fn(), del: jest.fn(), incr: jest.fn(), expire: jest.fn() };
    const otp = { sendOtp: jest.fn(), verifyOtp: jest.fn() };
    const tokens = {
      issueAccessToken: jest.fn(() => 'access-token'),
      issueRefreshToken: jest.fn(() => 'refresh-token'),
    };
    const audit = { log: jest.fn() };

    const service = new AuthService(prisma as never, redis as never, otp as never, tokens as never, audit as never);
    return { service, prisma, tokens, audit };
  };

  it('rejects callback when email domain is not mapped to any active tenant', async () => {
    const { service, prisma } = makeService();
    prisma.tenant.findFirst.mockResolvedValue(null);

    await expect(
      service.loginWithGoogle({ email: 'person@unknown.com', name: 'User Name', google_sub: 'sub-1' }),
    ).rejects.toThrow(ForbiddenException);
  });

  it('issues tokens for an existing active employee on Google callback', async () => {
    const { service, prisma, tokens, audit } = makeService();
    prisma.tenant.findFirst.mockResolvedValue({ id: 'tenant-1', domain: 'infosys.com' });
    prisma.user.findFirst.mockResolvedValue({
      id: 'user-1',
      email: 'person@infosys.com',
      role: Role.USER,
      tenant_id: 'tenant-1',
      is_employee: true,
      is_active: true,
      is_suspended: false,
      is_deleted: false,
    });
    prisma.user.update.mockResolvedValue({});
    prisma.session.create.mockResolvedValue({});

    const result = await service.loginWithGoogle(
      { email: 'person@infosys.com', name: 'User Name', google_sub: 'sub-1' },
      '127.0.0.1',
      'jest',
    );

    expect(tokens.issueAccessToken).toHaveBeenCalled();
    expect(tokens.issueRefreshToken).toHaveBeenCalled();
    expect(audit.log).toHaveBeenCalledWith({
      userId: 'user-1',
      tenantId: 'tenant-1',
      action: AuditAction.SSO_LOGIN,
      module: AuditModule.AUTH,
      ipAddress: '127.0.0.1',
      device: 'jest',
      metadata: { provider: 'GOOGLE' },
    });
    expect(result.access_token).toBe('access-token');
    expect(result.refresh_token).toBe('refresh-token');
  });
});

