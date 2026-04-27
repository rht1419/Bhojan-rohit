import { Processor, Process } from '@nestjs/bull';
import { Logger } from '@nestjs/common';
import type { Job } from 'bull';
import { PrismaService } from '../../prisma/prisma.service.js';
import { AuditService } from '../../audit/services/audit.service.js';
import { AuditAction, AuditModule, UploadStatus } from '@prisma/client';

interface BulkUploadJob {
  uploadId: string;
  tenantId: string;
  uploadedBy: string;
  csvText: string;
}

interface CsvRow {
  employee_id: string;
  email: string;
  full_name: string;
  department?: string;
}

interface RowError {
  row: number;
  employee_id?: string;
  error: string;
}

@Processor('employee-bulk-upload')
export class EmployeeBulkUploadProcessor {
  private readonly logger = new Logger(EmployeeBulkUploadProcessor.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
  ) {}

  @Process('process-upload')
  async handle(job: Job<BulkUploadJob>) {
    const { uploadId, tenantId, uploadedBy, csvText } = job.data;
    this.logger.log(`[BulkUpload] Processing job ${uploadId} for tenant ${tenantId}`);

    let successCount = 0;
    let failedCount = 0;
    const errors: RowError[] = [];

    try {
      // ── 1. Parse CSV ─────────────────────────────────────────────────────
      const lines = csvText.split(/\r?\n/).map((l) => l.trim()).filter(Boolean);
      if (lines.length < 2) {
        await this.markFailed(uploadId, [{ row: 0, error: 'CSV has no data rows.' }]);
        return;
      }

      const header = lines[0].toLowerCase().split(',').map((h) => h.trim());
      const requiredCols = ['employee_id', 'email', 'full_name'];
      const missing = requiredCols.filter((c) => !header.includes(c));
      if (missing.length > 0) {
        await this.markFailed(uploadId, [{ row: 0, error: `Missing required columns: ${missing.join(', ')}` }]);
        return;
      }

      const colIndex = (name: string) => header.indexOf(name);
      const dataRows = lines.slice(1);

      // ── 2. Process each row ───────────────────────────────────────────────
      for (let i = 0; i < dataRows.length; i++) {
        const rowNum = i + 2; // 1-based, header = row 1
        const cells = dataRows[i].split(',').map((c) => c.trim());

        const row: CsvRow = {
          employee_id: cells[colIndex('employee_id')] ?? '',
          email: cells[colIndex('email')] ?? '',
          full_name: cells[colIndex('full_name')] ?? '',
          department: colIndex('department') >= 0 ? cells[colIndex('department')] : undefined,
        };

        // Validate required fields
        if (!row.employee_id || !row.email || !row.full_name) {
          errors.push({ row: rowNum, employee_id: row.employee_id, error: 'Missing required field(s).' });
          failedCount++;
          continue;
        }

        // Basic email format check
        if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(row.email)) {
          errors.push({ row: rowNum, employee_id: row.employee_id, error: `Invalid email: ${row.email}` });
          failedCount++;
          continue;
        }

        try {
          // Upsert roster entry (unique: tenant_id + employee_id)
          await this.prisma.employeeRoster.upsert({
            where: {
              tenant_id_employee_id: {
                tenant_id: tenantId,
                employee_id: row.employee_id,
              },
            },
            update: {
              email: row.email,
              full_name: row.full_name,
              is_active: true,
            },
            create: {
              tenant_id: tenantId,
              employee_id: row.employee_id,
              email: row.email,
              full_name: row.full_name,
              is_active: true,
            },
          });
          successCount++;
        } catch (err: unknown) {
          const msg = err instanceof Error ? err.message : String(err);
          this.logger.warn(`[BulkUpload] Row ${rowNum} failed: ${msg}`);
          errors.push({ row: rowNum, employee_id: row.employee_id, error: msg });
          failedCount++;
        }
      }

      // ── 3. Update bulk_upload_logs with results ───────────────────────────
      // COMPLETED = all rows succeeded or partially succeeded (with logged errors)
      // FAILED = entire job crashed (caught below)
      const finalStatus = UploadStatus.COMPLETED;
      await this.prisma.bulkUploadLog.update({
        where: { id: uploadId },
        data: {
          status: finalStatus,
          success_count: successCount,
          failed_count: failedCount,
          error_details: errors.length > 0 ? (errors as unknown as object[]) : undefined,
        },
      });

      // ── 4. Audit log ──────────────────────────────────────────────────────
      await this.audit.log({
        userId: uploadedBy,
        tenantId,
        action: AuditAction.BULK_EMPLOYEE_UPLOAD,
        module: AuditModule.EMPLOYEE,
        targetId: uploadId,
        metadata: {
          total: successCount + failedCount,
          success_count: successCount,
          failed_count: failedCount,
          status: finalStatus,
        },
      });

      this.logger.log(
        `[BulkUpload] Job ${uploadId} done — ${successCount} ok / ${failedCount} failed`,
      );
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      this.logger.error(`[BulkUpload] Job ${uploadId} crashed: ${msg}`);
      await this.markFailed(uploadId, [
        { row: 0, error: `Unexpected processor error: ${msg}` },
      ]);
    }
  }

  private async markFailed(uploadId: string, errors: RowError[]) {
    await this.prisma.bulkUploadLog.update({
      where: { id: uploadId },
      data: {
        status: UploadStatus.FAILED,
        success_count: 0,
        failed_count: 0,
        error_details: errors as unknown as object[],
      },
    });
  }
}
