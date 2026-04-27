import { AuditAction, AuditModule, Role, SuspensionAction } from '@prisma/client';
import { AdminVendorService } from './admin-vendor.service';

describe('AdminVendorService (EP-28/EP-29)', () => {
  const makeService = () => {
    const prisma = {
      user: { findFirst: jest.fn(), update: jest.fn() },
      session: { findMany: jest.fn(), updateMany: jest.fn() },
      vendorSuspensionLog: { create: jest.fn() },
    };
    const redis = { set: jest.fn(), del: jest.fn() };
    const audit = { log: jest.fn() };
<<<<<<< HEAD
    const otp = { sendActivationEmail: jest.fn() };
    const service = new AdminVendorService(prisma as never, redis as never, audit as never, otp as never);
=======
    const service = new AdminVendorService(prisma as never, redis as never, audit as never);
>>>>>>> 9164b54b7ae96a96dfb046b32a6f1d92bc55e577
    return { service, prisma, redis, audit };
  };

  it('suspends vendor and revokes active sessions', async () => {
    const { service, prisma, audit } = makeService();
    prisma.user.findFirst.mockResolvedValue({
      id: 'vendor-1',
      role: Role.VENDOR,
      is_suspended: false,
      tenant_id: 'tenant-1',
    });
    prisma.session.findMany.mockResolvedValue([
      { refresh_token: 'ref-1', expires_at: new Date(Date.now() + 3600_000) },
    ]);
    prisma.user.update.mockResolvedValue({});
    prisma.session.updateMany.mockResolvedValue({});
    prisma.vendorSuspensionLog.create.mockResolvedValue({});

    const result = await service.suspendVendor('vendor-1', 'Policy violation', 'admin-1');

    expect(prisma.user.update).toHaveBeenCalled();
    expect(prisma.vendorSuspensionLog.create).toHaveBeenCalledWith(expect.objectContaining({
      data: expect.objectContaining({ action: SuspensionAction.SUSPENDED }),
    }));
    expect(audit.log).toHaveBeenCalledWith(expect.objectContaining({
      userId: 'admin-1',
      action: AuditAction.VENDOR_SUSPENDED,
      module: AuditModule.VENDOR,
    }));
    expect(result.message).toContain('suspended');
  });

  it('reactivates a suspended vendor', async () => {
    const { service, prisma, audit } = makeService();
    prisma.user.findFirst.mockResolvedValue({
      id: 'vendor-1',
      role: Role.VENDOR,
      is_suspended: true,
      tenant_id: 'tenant-1',
    });
    prisma.user.update.mockResolvedValue({});
    prisma.vendorSuspensionLog.create.mockResolvedValue({});

    const result = await service.reactivateVendor('vendor-1', 'Issue resolved', 'admin-1');

    expect(prisma.user.update).toHaveBeenCalled();
    expect(prisma.vendorSuspensionLog.create).toHaveBeenCalledWith(expect.objectContaining({
      data: expect.objectContaining({ action: SuspensionAction.REACTIVATED }),
    }));
    expect(audit.log).toHaveBeenCalledWith(expect.objectContaining({
      userId: 'admin-1',
      action: AuditAction.VENDOR_REACTIVATED,
      module: AuditModule.VENDOR,
    }));
    expect(result.message).toContain('reactivated');
  });
});

