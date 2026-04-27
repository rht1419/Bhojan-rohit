import { IsString, IsUUID, IsOptional, MinLength, MaxLength, Matches } from 'class-validator';

export class CompleteVendorDto {
  @IsString()
  @MinLength(5)
  @MaxLength(300)
  business_address: string;

  @IsString()
  @MinLength(2)
  @MaxLength(100)
  city: string;

  @IsString()
  @MinLength(2)
  @MaxLength(100)
  state: string;

  @IsString()
  @Matches(/^\d{6}$/, { message: 'pincode must be exactly 6 digits' })
  pincode: string;

  @IsUUID()
  tenant_id: string;

  @IsOptional()
  @IsString()
  @MaxLength(15)
  gstin?: string;
}
