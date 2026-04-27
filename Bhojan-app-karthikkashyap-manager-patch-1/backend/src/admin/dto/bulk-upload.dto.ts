import { IsOptional, IsUUID } from 'class-validator';

export class BulkUploadDto {
  @IsOptional()
  @IsUUID()
  tenant_id?: string;
}

