import { Type } from 'class-transformer';
import { IsEnum, IsISO8601, IsOptional, IsString, IsUUID, MaxLength, IsInt, Min, Max } from 'class-validator';
import { AppModule } from '@prisma/client';

export class CreateDelegationDto {
  @IsUUID()
  delegatee_id: string;

  @IsEnum(AppModule)
  module: AppModule;

  @IsISO8601()
  expires_at: string;

  @IsOptional()
  @IsISO8601()
  starts_at?: string;

  @IsOptional()
  @IsString()
  @MaxLength(300)
  reason?: string;
}

export class DelegationQueryDto {
  @IsOptional()
  @IsUUID()
  delegatee_id?: string;

  @IsOptional()
  @IsEnum(AppModule)
  module?: AppModule;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number = 20;
}

