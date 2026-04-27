import { IsString, Matches } from 'class-validator';

export class VendorLoginDto {
  @Matches(/^\+91[6-9]\d{9}$/, { message: 'Phone must be in format +91XXXXXXXXXX' })
  phone: string;

  @IsString()
  password: string;
}
