import { IsEmail, IsString, IsUUID, IsOptional, Matches, Length } from 'class-validator';

export class CreateVendorDto {
  @IsEmail()
  email: string;

  @Matches(/^\+91[6-9]\d{9}$/, { message: 'Phone must be in format +91XXXXXXXXXX' })
  phone: string;

  @IsString()
  @Length(2, 100)
  full_name: string;

  @IsString()
  @Length(2, 150)
  business_name: string;

  @IsUUID()
  tenant_id: string;

  @IsString()
  @Length(5, 300)
  business_address: string;

  @IsString()
  @Length(2, 100)
  city: string;

  @IsString()
  @Length(2, 100)
  state: string;

  @Matches(/^\d{6}$/, { message: 'Pincode must be 6 digits' })
  pincode: string;

  @IsOptional()
  @IsString()
  @Length(15, 15, { message: 'GSTIN must be exactly 15 characters' })
  gstin?: string;
}
