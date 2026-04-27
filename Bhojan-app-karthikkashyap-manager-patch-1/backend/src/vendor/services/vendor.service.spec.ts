import { NotFoundException } from '@nestjs/common';
import { AuditAction, AuditModule, Role } from '@prisma/client';
import { VendorService } from './vendor.service';

describe('VendorService (EP-19)', () => {
  const makeService = () => {
    const prisma = {
      user: { findFirst: jest.fn() },
      vendorProfile: { findUnique: jest.fn(), update: jest.fn() },
      session: { create: jest.fn() },
    };
    const redis = { get: jest.fn(), incr: jest.fn(), expire: jest.fn(), del: jest.fn() };
    const tokens = { issueAccessToken: jest.fn(), issueRefreshToken: jest.fn() };
    const audit = { log: jest.fn() };

<<<<<<< HEAD
    const otp = { sendOtp: jest.fn(), verifyOtp: jest.fn() };
    const service = new VendorService(prisma as never, redis as never, tokens as never, otp as never, audit as never);
=======
    const service = new VendorService(prisma as never, redis as never, tokens as never, audit as never);
>>>>>>> 9164b54b7ae96a96dfb046b32a6f1d92bc55e577
    return { service, prisma, audit };
  };

  it('updates vendor profile fields for the authenticated vendor', async () => {
    const { service, prisma, audit } = makeService();
    prisma.user.findFirst.mockResolvedValue({
      id: 'vendor-1',
      role: Role.VENDOR,
      is_active: true,
      is_verified: true,
      is_suspended: false,
      is_deleted: false,
      tenant_id: 'tenant-1',
      is_employee: false,
    });
    prisma.vendorProfile.findUnique.mockResolvedValue({ user_id: 'vendor-1' });
    prisma.vendorProfile.update.mockResolvedValue({
      user_id: 'vendor-1',
      business_name: 'New Outlet Name',
      business_address: 'Address',
      city: 'Bengaluru',
      logo_url: 'https://logo.test/img.png',
      fssai_number: '123456',
    });

    const result = await service.updateProfile('vendor-1', {
      business_name: 'New Outlet Name',
      business_address: 'Address',
      city: 'Bengaluru',
      logo_url: 'https://logo.test/img.png',
      fssai_number: '123456',
    });

    expect(prisma.vendorProfile.update).toHaveBeenCalled();
    expect(audit.log).toHaveBeenCalledWith({
      userId: 'vendor-1',
      action: AuditAction.PROFILE_UPDATED,
      module: AuditModule.VENDOR,
    });
    expect(result.vendor_profile.business_name).toBe('New Outlet Name');
  });

  it('throws USER_NOT_FOUND when vendor profile does not exist', async () => {
    const { service, prisma } = makeService();
    prisma.user.findFirst.mockResolvedValue({
      id: 'vendor-1',
      role: Role.VENDOR,
      is_active: true,
      is_verified: true,
      is_suspended: false,
      is_deleted: false,
      tenant_id: 'tenant-1',
      is_employee: false,
    });
    prisma.vendorProfile.findUnique.mockResolvedValue(null);

    await expect(service.updateProfile('vendor-1', { city: 'Bengaluru' })).rejects.toThrow(NotFoundException);
  });
});

