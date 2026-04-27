import { AppModule, AuditAction, AuditModule, Role } from '@prisma/client';
import { AdminDelegationService } from './admin-delegation.service';

describe('AdminDelegationService (EP-30/31/32 + cron)', () => {
  const makeService = () => {
    const prisma = {
      user: { findFirst: jest.fn() },
      delegation: { create: jest.fn(), findMany: jest.fn(), findUnique: jest.fn(), update: jest.fn() },
    };
    const redis = { set: jest.fn(), del: jest.fn() };
    const audit = { log: jest.fn() };
    const service = new AdminDelegationService(prisma as never, redis as never, audit as never);
    return { service, prisma, redis, audit };
  };

  it('creates delegation and caches key in redis', async () => {
    const { service, prisma, redis, audit } = makeService();
    prisma.user.findFirst.mockResolvedValue({ id: 'delegatee-1', role: Role.OPS_ADMIN, is_active: true });
    prisma.delegation.create.mockResolvedValue({
      id: 'del-1',
      expires_at: new Date(Date.now() + 3600_000),
      module: AppModule.FINANCE,
    });

    const result = await service.createDelegation('super-1', {
      delegatee_id: 'delegatee-1',
      module: AppModule.FINANCE,
      expires_at: new Date(Date.now() + 3600_000).toISOString(),
    });

    expect(redis.set).toHaveBeenCalled();
    expect(audit.log).toHaveBeenCalledWith(expect.objectContaining({
      userId: 'super-1',
      action: AuditAction.DELEGATE_GRANTED,
      module: AuditModule.DELEGATION,
    }));
    expect(result.delegation_id).toBe('del-1');
  });

  it('revokes delegation and clears redis key', async () => {
    const { service, prisma, redis, audit } = makeService();
    prisma.delegation.findUnique.mockResolvedValue({
      id: 'del-1',
      delegatee_id: 'delegatee-1',
      module: AppModule.FINANCE,
      is_active: true,
    });
    prisma.delegation.update.mockResolvedValue({});

    const result = await service.revokeDelegation('del-1', 'super-1');

    expect(redis.del).toHaveBeenCalledWith('delegate:delegatee-1:FINANCE');
    expect(audit.log).toHaveBeenCalledWith(expect.objectContaining({
      userId: 'super-1',
      action: AuditAction.DELEGATE_REVOKED,
      module: AuditModule.DELEGATION,
    }));
    expect(result.message).toContain('revoked');
  });
});

