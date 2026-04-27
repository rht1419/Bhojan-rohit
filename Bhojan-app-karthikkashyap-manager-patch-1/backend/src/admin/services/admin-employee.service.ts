import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { InjectQueue } from '@nestjs/bull';
import type { Queue } from 'bull';
import { randomUUID } from 'crypto';
import { PrismaService } from '../../prisma/prisma.service.js';
import { RedisService } from '../../redis/redis.service.js';
import { AuditService } from '../../audit/services/audit.service.js';
import type { AuditLogQueryDto } from '../dto/audit-log-query.dto.js';
import type { AuditExportQueryDto } from '../dto/audit-export-query.dto.js';
import type { BulkUploadDto } from '../dto/bulk-upload.dto.js';
import type { OffboardEmployeeDto } from '../dto/offboard-employee.dto.js';
import type { SessionsQueryDto } from '../dto/sessions-query.dto.js';
import { AuditAction, AuditModule, Role, Prisma, UploadStatus } from '@prisma/client';

const REFRESH_TTL_SECONDS = 7 * 24 * 60 * 60;

@Injectable()
export class AdminEmployeeService {
  private readonly logger = new Logger(AdminEmployeeService.name);

  constructor(
    private prisma: PrismaService,
    private redis: RedisService,
    private audit: AuditService,
    @InjectQueue('employee-bulk-upload') private readonly bulkUploadQueue: Queue,
    @InjectQueue('audit-export') private readonly auditExportQueue: Queue,
  ) {}

  // ── EP-22: Admin Audit Log Query ───────────────────────────────────────────

  async getAuditLogs(
    callerRole: Role,
    callerTenantId: string | null,
    query: AuditLogQueryDto,
  ) {
    const page = query.page ?? 1;
    const limit = query.limit ?? 50;
    const skip = (page - 1) * limit;

    const where: Prisma.AuditLogWhereInput = {};

    // OPS_ADMIN can only view their own tenant
    if (callerRole === Role.OPS_ADMIN) {
      where.tenant_id = callerTenantId ?? undefined;
    } else if (query.tenant_id) {
      where.tenant_id = query.tenant_id;
    }

    if (query.user_id) where.user_id = query.user_id;
    if (query.action) where.action = query.action;
    if (query.module) where.module = query.module;

    if (query.from_date || query.to_date) {
      where.created_at = {};
      if (query.from_date) where.created_at.gte = new Date(query.from_date);
      if (query.to_date) where.created_at.lte = new Date(query.to_date);
    }

    const [total, logs] = await Promise.all([
      this.prisma.auditLog.count({ where }),
      this.prisma.auditLog.findMany({
        where,
        orderBy: { created_at: 'desc' },
        skip,
        take: limit,
        select: {
          id: true,
          user_id: true,
          tenant_id: true,
          action: true,
          module: true,
          target_id: true,
          ip_address: true,
          device: true,
          metadata: true,
          created_at: true,
        },
      }),
    ]);

    return {
      logs,
      pagination: {
        page,
        limit,
        total,
        total_pages: Math.ceil(total / limit),
      },
    };
  }

  // ── EP-26: Employee Offboarding ────────────────────────────────────────────

  async offboardEmployee(
    targetUserId: string,
    dto: OffboardEmployeeDto,
    callerUserId: string,
    callerRole: Role,
    callerTenantId: string | null,
    ip?: string,
  ) {
    const target = await this.prisma.user.findFirst({
      where: { id: targetUserId, role: Role.USER },
    });
    if (!target) {
      throw new NotFoundException({ code: 'USER_NOT_FOUND', message: 'Employee not found.' });
    }

    if (callerRole === Role.OPS_ADMIN && target.tenant_id !== callerTenantId) {
      throw new ForbiddenException({ code: 'TENANT_MISMATCH', message: 'You can only offboard employees from your own tenant.' });
    }

    // Deactivate user account
    await this.prisma.user.update({
      where: { id: targetUserId },
      data: { is_active: false, deactivated_at: new Date() },
    });

    // Deactivate roster entry
    if (target.tenant_id && target.employee_id) {
      await this.prisma.employeeRoster.updateMany({
        where: { tenant_id: target.tenant_id, employee_id: target.employee_id },
        data: { is_active: false },
      });
    }

    // Revoke all active sessions
    const activeSessions = await this.prisma.session.findMany({
      where: { user_id: targetUserId, is_revoked: false },
      select: { id: true, refresh_token: true, expires_at: true },
    });

    if (activeSessions.length > 0) {
      await this.prisma.session.updateMany({
        where: { user_id: targetUserId, is_revoked: false },
        data: { is_revoked: true },
      });

      for (const session of activeSessions) {
        const ttl = Math.max(0, Math.floor((session.expires_at.getTime() - Date.now()) / 1000));
        if (ttl > 0) {
          await this.redis.set(`blacklist:${session.refresh_token}`, '1', ttl);
        }
      }
    }

    const metadata = { performed_by: callerUserId, reason: dto.reason, sessions_revoked: activeSessions.length };

    await Promise.all([
      this.audit.log({
        userId: callerUserId, tenantId: callerTenantId ?? undefined,
        action: AuditAction.OFFBOARDING_DEACTIVATION,
        module: AuditModule.EMPLOYEE,
        targetId: targetUserId, ipAddress: ip, metadata,
      }),
      this.audit.log({
        userId: callerUserId, tenantId: target.tenant_id ?? undefined,
        action: AuditAction.EMPLOYEE_OFFBOARDED,
        module: AuditModule.EMPLOYEE,
        targetId: targetUserId, ipAddress: ip,
        metadata: { employee_id: target.employee_id, reason: dto.reason },
      }),
    ]);

    return { success: true, message: 'Employee offboarded successfully.' };
  }

  // ── EP-33: List Sessions ───────────────────────────────────────────────────

  async getSessions(query: SessionsQueryDto) {
    const where: Prisma.SessionWhereInput = {};
    if (query.user_id) where.user_id = query.user_id;
    if (query.is_active !== undefined) {
      where.is_revoked = !query.is_active;
    } else {
      where.is_revoked = false; // default: active only
    }

    const sessions = await this.prisma.session.findMany({
      where,
      orderBy: { created_at: 'desc' },
      select: {
        id: true, user_id: true, device: true, ip_address: true,
        is_revoked: true, created_at: true, expires_at: true,
        user: { select: { email: true } },
      },
    });

    return {
      sessions: sessions.map(s => ({
        id: s.id,
        user_id: s.user_id,
        user_email: s.user.email,
        device: s.device,
        ip_address: s.ip_address,
        is_revoked: s.is_revoked,
        created_at: s.created_at,
        expires_at: s.expires_at,
      })),
    };
  }

  // ── EP-34: Revoke Session ──────────────────────────────────────────────────

  async revokeSession(sessionId: string, adminId: string) {
    const session = await this.prisma.session.findUnique({ where: { id: sessionId } });
    if (!session) {
      throw new NotFoundException({ code: 'SESSION_NOT_FOUND', message: 'Session not found.' });
    }

    await this.prisma.session.update({ where: { id: sessionId }, data: { is_revoked: true } });

    const ttl = Math.max(0, Math.floor((session.expires_at.getTime() - Date.now()) / 1000));
    if (ttl > 0) {
      await this.redis.set(`blacklist:${session.refresh_token}`, '1', ttl);
    }

    await this.audit.log({
      userId: adminId, action: AuditAction.SESSION_REVOKED,
      module: AuditModule.SESSION, targetId: session.user_id,
      metadata: { session_id: sessionId },
    });

    return { success: true, message: 'Session revoked.' };
  }

  // ── EP-23: Audit logs export (async) ────────────────────────────────────────
  async exportAuditLogs(callerRole: Role, callerTenantId: string | null, query: AuditExportQueryDto) {
    if (query.job_id) {
      const status = await this.redis.get(`audit_export:${query.job_id}`);
      if (!status) throw new NotFoundException('Export job not found or expired.');
      return JSON.parse(status);
    }

    const jobId = randomUUID();
    await this.redis.set(
      `audit_export:${jobId}`,
      JSON.stringify({ job_id: jobId, status: 'PENDING', message: 'Export is being generated.' }),
      3600,
    );

    await this.auditExportQueue.add(
      'generate-export',
      {
        jobId,
        callerRole,
        callerTenantId,
        filters: query,
      },
      { attempts: 2, removeOnComplete: true, removeOnFail: 50 },
    );

    return {
      job_id: jobId,
      status: 'PENDING',
      message: 'Export request accepted. Poll this endpoint with job_id.',
    };
  }

  // ── EP-24: Bulk employee upload (async) ─────────────────────────────────────
  async uploadEmployeesCsv(
    callerRole: Role,
    callerTenantId: string | null,
    callerUserId: string,
    dto: BulkUploadDto,
    file: Express.Multer.File,
  ) {
    if (!file) throw new BadRequestException('CSV file is required.');
    if (!file.originalname.toLowerCase().endsWith('.csv')) {
      throw new BadRequestException('Only CSV files are allowed.');
    }

    const tenantId =
      callerRole === Role.SUPER_ADMIN ? dto.tenant_id ?? null : callerTenantId;
    if (!tenantId) throw new BadRequestException('tenant_id is required for SUPER_ADMIN.');

    const lines = file.buffer.toString('utf8').split(/\r?\n/).filter((line) => line.trim().length > 0);
    const totalRecords = Math.max(0, lines.length - 1);
    if (totalRecords === 0) throw new BadRequestException('CSV has no data rows.');

    const log = await this.prisma.bulkUploadLog.create({
      data: {
        tenant_id: tenantId,
        uploaded_by: callerUserId,
        file_name: file.originalname,
        total_records: totalRecords,
        status: UploadStatus.PENDING,
      },
      select: { id: true },
    });

    await this.bulkUploadQueue.add(
      'process-upload',
      {
        uploadId: log.id,
        tenantId,
        uploadedBy: callerUserId,
        csvText: file.buffer.toString('utf8'),
      },
      { attempts: 2, removeOnComplete: true, removeOnFail: 50 },
    );

    return {
      upload_id: log.id,
      status: 'PENDING',
      total_records: totalRecords,
      message: 'Upload accepted. Processing in background.',
    };
  }

  // ── EP-25: Bulk upload status poll ──────────────────────────────────────────
  async getBulkUploadStatus(id: string, callerRole: Role, callerTenantId: string | null) {
    const log = await this.prisma.bulkUploadLog.findUnique({
      where: { id },
      select: {
        id: true,
        tenant_id: true,
        status: true,
        total_records: true,
        success_count: true,
        failed_count: true,
        error_details: true,
        created_at: true,
        updated_at: true,
      },
    });
    if (!log) throw new NotFoundException('Upload job not found.');
    if (callerRole === Role.OPS_ADMIN && log.tenant_id !== callerTenantId) {
      throw new ForbiddenException('Cannot access uploads from another tenant.');
    }

    return {
      upload_id: log.id,
      status: log.status,
      total_records: log.total_records,
      success_count: log.success_count,
      failed_count: log.failed_count,
      error_details: log.error_details,
      created_at: log.created_at,
      updated_at: log.updated_at,
    };
  }
}
