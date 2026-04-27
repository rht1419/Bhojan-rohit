import { IsOptional, IsUUID } from 'class-validator';
import { AuditLogQueryDto } from './audit-log-query.dto.js';

export class AuditExportQueryDto extends AuditLogQueryDto {
  @IsOptional()
  @IsUUID()
  job_id?: string;
}

