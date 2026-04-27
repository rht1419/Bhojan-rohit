import { IsOptional, IsString, IsUrl, MaxLength } from 'class-validator';

export class VendorProfileUpdateDto {
  @IsOptional()
  @IsString()
  @MaxLength(120)
  business_name?: string;

  @IsOptional()
  @IsString()
  @MaxLength(250)
  business_address?: string;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  city?: string;

  @IsOptional()
  @IsUrl({}, { message: 'logo_url must be a valid URL' })
  logo_url?: string;

  @IsOptional()
  @IsString()
  @MaxLength(40)
  fssai_number?: string;
}

