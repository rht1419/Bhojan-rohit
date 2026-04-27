import { Processor, Process } from '@nestjs/bull';
import { Logger } from '@nestjs/common';
import type { Job } from 'bull';
import { PrismaService } from '../../prisma/prisma.service.js';
import { RedisService } from '../../redis/redis.service.js';
import { AuditModule, Prisma, Role } from '@prisma/client';
import type { AuditExportQueryDto } from '../dto/audit-export-query.dto.js';

interface AuditExportJob {
  jobId: string;
  callerRole: Role;
  callerTenantId: string | null;
  filters: AuditExportQueryDto;
}

/** TTL for cached export result in Redis (1 hour) */
const EXPORT_RESULT_TTL = 3600;

/** Maximum rows per export to prevent OOM on large datasets */
const MAX_EXPORT_ROWS = 100_000;

@Processor('audit-export')
export class AuditExportProcessor {
  private readonly logger = new Logger(AuditExportProcessor.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
  ) {}

  @Process('generate-export')
  async handle(job: Job<AuditExportJob>) {
    const { jobId, callerRole, callerTenantId, filters } = job.data;
    this.logger.log(`[AuditExport] Starting job ${jobId}`);

    try {
      // ── 1. Build Prisma WHERE clause (same logic as EP-22 query) ──────────
      const where: Prisma.AuditLogWhereInput = {};

      if (callerRole === Role.OPS_ADMIN) {
        where.tenant_id = callerTenantId ?? undefined;
      } else if (filters.tenant_id) {
        where.tenant_id = filters.tenant_id;
      }

      if (filters.user_id) where.user_id = filters.user_id;
      if (filters.action) where.action = filters.action;
      if (filters.module) where.module = filters.module as AuditModule;

      if (filters.from_date || filters.to_date) {
        where.created_at = {};
        if (filters.from_date) where.created_at.gte = new Date(filters.from_date);
        if (filters.to_date) where.created_at.lte = new Date(filters.to_date);
      }

      // ── 2. Fetch rows (capped) ────────────────────────────────────────────
      const rows = await this.prisma.auditLog.findMany({
        where,
        orderBy: { created_at: 'desc' },
        take: MAX_EXPORT_ROWS,
        select: {
          id: true,
          user_id: true,
          tenant_id: true,
          action: true,
          module: true,
          target_id: true,
          ip_address: true,
          device: true,
          created_at: true,
        },
      });

      // ── 3. Convert to CSV ─────────────────────────────────────────────────
      const csvHeader = 'id,user_id,tenant_id,action,module,target_id,ip_address,device,created_at';
      const csvRows = rows.map((r) =>
        [
          r.id,
          r.user_id ?? '',
          r.tenant_id ?? '',
          r.action,
          r.module,
          r.target_id ?? '',
          r.ip_address ?? '',
          r.device ?? '',
          r.created_at.toISOString(),
        ]
          .map((v) => `"${String(v).replace(/"/g, '""')}"`)
          .join(','),
      );
      const csvContent = [csvHeader, ...csvRows].join('\n');

      // ── 4. Store in Redis as base64 (dev/staging — no GCS configured yet) ─
      // Production upgrade: upload to GCS → get signed URL → store URL in Redis
      const csvBase64 = Buffer.from(csvContent, 'utf8').toString('base64');

      const resultPayload = JSON.stringify({
        job_id: jobId,
        status: 'COMPLETED',
        row_count: rows.length,
        // In production this will be a GCS signed URL (1h TTL)
        download_url: `data:text/csv;base64,${csvBase64}`,
        expires_in: EXPORT_RESULT_TTL,
        generated_at: new Date().toISOString(),
        message:
          rows.length === MAX_EXPORT_ROWS
            ? `Export capped at ${MAX_EXPORT_ROWS.toLocaleString()} rows. Use date filters to narrow the range.`
            : `Export ready — ${rows.length} rows.`,
      });

      await this.redis.set(`audit_export:${jobId}`, resultPayload, EXPORT_RESULT_TTL);
      this.logger.log(`[AuditExport] Job ${jobId} completed — ${rows.length} rows`);
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      this.logger.error(`[AuditExport] Job ${jobId} failed: ${msg}`);

      await this.redis.set(
        `audit_export:${jobId}`,
        JSON.stringify({
          job_id: jobId,
          status: 'FAILED',
          message: `Export failed: ${msg}`,
        }),
        EXPORT_RESULT_TTL,
      );
    }
  }
}
