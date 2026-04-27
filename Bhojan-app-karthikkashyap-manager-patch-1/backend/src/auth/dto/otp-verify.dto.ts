<<<<<<< HEAD
import { Transform } from 'class-transformer';
import { IsOptional, IsString, Length, Matches } from 'class-validator';

export class OtpVerifyDto {
  @Transform(({ value }) => value?.toString().trim())
  @Matches(/^(\+91|91)?[6-9]\d{9}$/, { message: 'Phone must be a valid Indian mobile number' })
  phone: string;

  // Accept both numeric and string OTP payloads, then validate as strict 6-digit string.
  @Transform(({ value }) => value?.toString().trim())
=======
import { IsString, Length, Matches } from 'class-validator';

export class OtpVerifyDto {
  @Matches(/^\+91[6-9]\d{9}$/, { message: 'Phone must be in format +91XXXXXXXXXX' })
  phone: string;

>>>>>>> 9164b54b7ae96a96dfb046b32a6f1d92bc55e577
  @IsString()
  @Length(6, 6, { message: 'OTP must be exactly 6 digits' })
  @Matches(/^\d{6}$/, { message: 'OTP must be numeric' })
  otp: string;
<<<<<<< HEAD

  // Frontend may send this for traceability; keep optional to avoid whitelist rejection.
  @IsOptional()
  @Transform(({ value }) => value?.toString())
  @IsString()
  otp_reference?: string;
=======
>>>>>>> 9164b54b7ae96a96dfb046b32a6f1d92bc55e577
}
