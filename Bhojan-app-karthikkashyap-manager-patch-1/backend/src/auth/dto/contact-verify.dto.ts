import { IsUUID, IsString, Matches } from 'class-validator';

export class ContactVerifyDto {
  @IsUUID()
  request_id: string;

  @IsString()
  @Matches(/^\d{6}$/, { message: 'OTP must be exactly 6 digits' })
  otp_old: string;

  @IsString()
  @Matches(/^\d{6}$/, { message: 'OTP must be exactly 6 digits' })
  otp_new: string;
}
