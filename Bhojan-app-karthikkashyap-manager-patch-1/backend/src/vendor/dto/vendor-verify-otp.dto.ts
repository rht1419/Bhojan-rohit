import { IsString, Matches } from 'class-validator';

export class VendorVerifyOtpDto {
  @IsString()
  @Matches(/^\+91[6-9]\d{9}$/, { message: 'phone must be in format +91XXXXXXXXXX' })
  phone: string;

  @IsString()
  @Matches(/^\d{6}$/, { message: 'otp must be exactly 6 digits' })
  otp: string;
}
