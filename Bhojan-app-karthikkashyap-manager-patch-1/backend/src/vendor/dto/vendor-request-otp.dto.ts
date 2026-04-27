import { IsString, Matches } from 'class-validator';

export class VendorRequestOtpDto {
  @IsString()
  @Matches(/^\+91[6-9]\d{9}$/, { message: 'phone must be in format +91XXXXXXXXXX' })
  phone: string;
}
