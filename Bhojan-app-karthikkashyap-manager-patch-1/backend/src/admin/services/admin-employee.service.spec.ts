import { BadRequestException, ForbiddenException, NotFoundException } from '@nestjs/common';
import { AuditAction, AuditModule, Role, UploadStatus } from '@prisma/client';
import { AdminEmployeeService } from './admin-employee.service';

// ── Shared factory ────────────────────────────────────────────────────────────

const makeService = () => {
  const prisma = {
    auditLog: { count: jest.fn(), findMany: jest.fn() },
    user: { findFirst: jest.fn(), update: jest.fn() },
    session: { findMany: jest.fn(), updateMany: jest.fn(), findUnique: jest.fn(), update: jest.fn() },
    employeeRoster: { updateMany: jest.fn() },
    bulkUploadLog: { create: jest.fn(), findUnique: jest.fn() },
  };
  const redis = { get: jest.fn(), set: jest.fn(), del: jest.fn() };
  const audit = { log: jest.fn() };
  const bulkUploadQueue = { add: jest.fn() };
  const auditExportQueue = { add: jest.fn() };

  const service = new AdminEmployeeService(
    prisma as never,
    redis as never,
    audit as never,
    bulkUploadQueue as never,
    auditExportQueue as never,
  );

  return { service, prisma, redis, audit, bulkUploadQueue, auditExportQueue };
};

// ── EP-22: getAuditLogs ────────────────────────────────────────────────────────

describe('AdminEmployeeService.getAuditLogs (EP-22)', () => {
  it('returns paginated audit logs with default pagination', async () => {
    const { service, prisma } = makeService();
    prisma.auditLog.count.mockResolvedValue(3);
    prisma.auditLog.findMany.mockResolvedValue([
      { id: 'log-1', user_id: 'u-1', action: 'USER_LOGIN', module: 'AUTH', created_at: new Date() },
    ]);

    const result = await service.getAuditLogs(Role.SUPER_ADMIN, null, {});

    expect(prisma.auditLog.findMany).toHaveBeenCalled();
    expect(result.logs).toHaveLength(1);
    expect(result.pagination.total).toBe(3);
  });

  it('restricts OPS_ADMIN to own tenant', async () => {
    const { service, prisma } = makeService();
    prisma.auditLog.count.mockResolvedValue(0);
    prisma.auditLog.findMany.mockResolvedValue([]);

    await service.getAuditLogs(Role.OPS_ADMIN, 'tenant-42', {});

    const callArgs = prisma.auditLog.findMany.mock.calls[0][0];
    expect(callArgs.where.tenant_id).toBe('tenant-42');
  });

  it('allows SUPER_ADMIN to filter by any tenant_id', async () => {
    const { service, prisma } = makeService();
    prisma.auditLog.count.mockResolvedValue(0);
    prisma.auditLog.findMany.mockResolvedValue([]);

    await service.getAuditLogs(Role.SUPER_ADMIN, null, { tenant_id: 'tenant-99' });

    const callArgs = prisma.auditLog.findMany.mock.calls[0][0];
    expect(callArgs.where.tenant_id).toBe('tenant-99');
  });
});

// ── EP-23: exportAuditLogs ─────────────────────────────────────────────────────

describe('AdminEmployeeService.exportAuditLogs (EP-23)', () => {
  it('enqueues a new export job and returns PENDING status', async () => {
    const { service, redis, auditExportQueue } = makeService();

    const result = await service.exportAuditLogs(Role.SUPER_ADMIN, null, {});

    expect(redis.set).toHaveBeenCalledWith(
      expect.stringMatching(/^audit_export:/),
      expect.stringContaining('PENDING'),
      3600,
    );
    expect(auditExportQueue.add).toHaveBeenCalledWith(
      'generate-export',
      expect.objectContaining({ callerRole: Role.SUPER_ADMIN }),
      expect.any(Object),
    );
    expect(result.status).toBe('PENDING');
    expect(result.job_id).toBeTruthy();
  });

  it('returns cached status when job_id is provided (poll)', async () => {
    const { service, redis } = makeService();
    const cached = JSON.stringify({ job_id: 'j-1', status: 'COMPLETED', download_url: 'data:...' });
    redis.get.mockResolvedValue(cached);

    const result = await service.exportAuditLogs(Role.SUPER_ADMIN, null, { job_id: 'j-1' });

    expect(redis.get).toHaveBeenCalledWith('audit_export:j-1');
    expect(result.status).toBe('COMPLETED');
  });

  it('throws 404 when polled job_id not found in Redis', async () => {
    const { service, redis } = makeService();
    redis.get.mockResolvedValue(null);

    await expect(
      service.exportAuditLogs(Role.SUPER_ADMIN, null, { job_id: 'missing-id' }),
    ).rejects.toThrow(NotFoundException);
  });
});

// ── EP-24: uploadEmployeesCsv ──────────────────────────────────────────────────

describe('AdminEmployeeService.uploadEmployeesCsv (EP-24)', () => {
  const makeFile = (content: string, name = 'employees.csv'): Express.Multer.File =>
    ({
      originalname: name,
      buffer: Buffer.from(content, 'utf8'),
      mimetype: 'text/csv',
    } as Express.Multer.File);

  it('creates BulkUploadLog and enqueues job for valid CSV', async () => {
    const { service, prisma, bulkUploadQueue } = makeService();
    prisma.bulkUploadLog.create.mockResolvedValue({ id: 'upload-1' });

    const csv = 'employee_id,email,full_name\nEMP001,emp@test.com,Test User';
    const result = await service.uploadEmployeesCsv(
      Role.OPS_ADMIN, 'tenant-1', 'admin-1', {}, makeFile(csv),
    );

    expect(prisma.bulkUploadLog.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          status: UploadStatus.PENDING,
          total_records: 1,
        }),
      }),
    );
    expect(bulkUploadQueue.add).toHaveBeenCalledWith(
      'process-upload',
      expect.objectContaining({ uploadId: 'upload-1', tenantId: 'tenant-1' }),
      expect.any(Object),
    );
    expect(result.upload_id).toBe('upload-1');
    expect(result.status).toBe('PENDING');
  });

  it('rejects non-CSV files', async () => {
    const { service } = makeService();
    const file = makeFile('data', 'employees.xlsx');

    await expect(
      service.uploadEmployeesCsv(Role.OPS_ADMIN, 'tenant-1', 'admin-1', {}, file),
    ).rejects.toThrow(BadRequestException);
  });

  it('rejects CSV with no data rows', async () => {
    const { service } = makeService();
    const csv = 'employee_id,email,full_name';
    await expect(
      service.uploadEmployeesCsv(Role.OPS_ADMIN, 'tenant-1', 'admin-1', {}, makeFile(csv)),
    ).rejects.toThrow(BadRequestException);
  });

  it('rejects missing file', async () => {
    const { service } = makeService();
    await expect(
      service.uploadEmployeesCsv(Role.OPS_ADMIN, 'tenant-1', 'admin-1', {}, null as never),
    ).rejects.toThrow(BadRequestException);
  });

  it('requires tenant_id for SUPER_ADMIN with no tenant context', async () => {
    const { service } = makeService();
    const csv = 'employee_id,email,full_name\nEMP001,e@t.com,U';
    await expect(
      service.uploadEmployeesCsv(Role.SUPER_ADMIN, null, 'admin-1', {}, makeFile(csv)),
    ).rejects.toThrow(BadRequestException);
  });
});

// ── EP-25: getBulkUploadStatus ─────────────────────────────────────────────────

describe('AdminEmployeeService.getBulkUploadStatus (EP-25)', () => {
  it('returns upload status for the correct tenant', async () => {
    const { service, prisma } = makeService();
    prisma.bulkUploadLog.findUnique.mockResolvedValue({
      id: 'upload-1',
      tenant_id: 'tenant-1',
      status: UploadStatus.COMPLETED,
      total_records: 10,
      success_count: 9,
      failed_count: 1,
      error_details: [],
      created_at: new Date(),
      updated_at: new Date(),
    });

    const result = await service.getBulkUploadStatus('upload-1', Role.SUPER_ADMIN, null);

    expect(result.upload_id).toBe('upload-1');
    expect(result.status).toBe(UploadStatus.COMPLETED);
    expect(result.success_count).toBe(9);
  });

  it('throws 404 for unknown upload ID', async () => {
    const { service, prisma } = makeService();
    prisma.bulkUploadLog.findUnique.mockResolvedValue(null);

    await expect(service.getBulkUploadStatus('bad-id', Role.SUPER_ADMIN, null)).rejects.toThrow(
      NotFoundException,
    );
  });

  it('throws 403 when OPS_ADMIN accesses another tenant upload', async () => {
    const { service, prisma } = makeService();
    prisma.bulkUploadLog.findUnique.mockResolvedValue({
      id: 'upload-1',
      tenant_id: 'tenant-OTHER',
      status: UploadStatus.PENDING,
    });

    await expect(
      service.getBulkUploadStatus('upload-1', Role.OPS_ADMIN, 'tenant-1'),
    ).rejects.toThrow(ForbiddenException);
  });
});

// ── EP-26: offboardEmployee ────────────────────────────────────────────────────

describe('AdminEmployeeService.offboardEmployee (EP-26)', () => {
  it('deactivates user, roster, and revokes sessions', async () => {
    const { service, prisma, redis, audit } = makeService();
    prisma.user.findFirst.mockResolvedValue({
      id: 'emp-1', role: Role.USER, tenant_id: 'tenant-1', employee_id: 'EMP001',
    });
    prisma.session.findMany.mockResolvedValue([
      { id: 's-1', refresh_token: 'ref-1', expires_at: new Date(Date.now() + 3600_000) },
    ]);
    prisma.user.update.mockResolvedValue({});
    prisma.employeeRoster.updateMany.mockResolvedValue({});
    prisma.session.updateMany.mockResolvedValue({});

    await service.offboardEmployee('emp-1', { reason: 'End of contract' }, 'admin-1', Role.SUPER_ADMIN, null);

    expect(prisma.user.update).toHaveBeenCalledWith(expect.objectContaining({
      where: { id: 'emp-1' },
      data: expect.objectContaining({ is_active: false }),
    }));
    expect(prisma.session.updateMany).toHaveBeenCalled();
    expect(redis.set).toHaveBeenCalledWith(expect.stringMatching(/^blacklist:/), '1', expect.any(Number));
    expect(audit.log).toHaveBeenCalledWith(expect.objectContaining({
      action: AuditAction.EMPLOYEE_OFFBOARDED,
      module: AuditModule.EMPLOYEE,
    }));
  });

  it('throws 404 for unknown employee', async () => {
    const { service, prisma } = makeService();
    prisma.user.findFirst.mockResolvedValue(null);

    await expect(
      service.offboardEmployee('bad-id', { reason: 'test' }, 'admin-1', Role.SUPER_ADMIN, null),
    ).rejects.toThrow(NotFoundException);
  });

  it('throws 403 when OPS_ADMIN tries to offboard another tenant employee', async () => {
    const { service, prisma } = makeService();
    prisma.user.findFirst.mockResolvedValue({
      id: 'emp-1', role: Role.USER, tenant_id: 'tenant-other', employee_id: 'EMP001',
    });

    await expect(
      service.offboardEmployee('emp-1', { reason: 'test' }, 'admin-1', Role.OPS_ADMIN, 'tenant-mine'),
    ).rejects.toThrow(ForbiddenException);
  });
});

// ── EP-33/34: Sessions ────────────────────────────────────────────────────────

describe('AdminEmployeeService — sessions (EP-33/34)', () => {
  it('EP-33: returns active sessions (default: is_revoked=false)', async () => {
    const { service, prisma } = makeService();
    prisma.session.findMany.mockResolvedValue([
      {
        id: 's-1', user_id: 'u-1', device: 'Flutter/iOS', ip_address: '1.2.3.4',
        is_revoked: false, created_at: new Date(), expires_at: new Date(Date.now() + 3600_000),
        user: { email: 'user@test.com' },
      },
    ]);

    const result = await service.getSessions({});

    expect(result.sessions).toHaveLength(1);
    expect(result.sessions[0].user_email).toBe('user@test.com');
  });

  it('EP-34: revokes a session and blacklists the refresh token', async () => {
    const { service, prisma, redis, audit } = makeService();
    const expiresAt = new Date(Date.now() + 3600_000);
    prisma.session.findUnique.mockResolvedValue({
      id: 's-1', user_id: 'u-1', refresh_token: 'ref-1', expires_at: expiresAt, is_revoked: false,
    });
    prisma.session.update.mockResolvedValue({});

    await service.revokeSession('s-1', 'admin-1');

    expect(prisma.session.update).toHaveBeenCalledWith(expect.objectContaining({
      where: { id: 's-1' },
      data: { is_revoked: true },
    }));
    expect(redis.set).toHaveBeenCalledWith('blacklist:ref-1', '1', expect.any(Number));
    expect(audit.log).toHaveBeenCalledWith(expect.objectContaining({
      action: AuditAction.SESSION_REVOKED,
      module: AuditModule.SESSION,
    }));
  });

  it('EP-34: throws 404 when session not found', async () => {
    const { service, prisma } = makeService();
    prisma.session.findUnique.mockResolvedValue(null);

    await expect(service.revokeSession('bad-id', 'admin-1')).rejects.toThrow(NotFoundException);
  });
});
