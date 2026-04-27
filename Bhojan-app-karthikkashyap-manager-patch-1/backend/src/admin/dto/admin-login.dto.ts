import { IsEmail, IsOptional, IsString, Matches } from 'class-validator';

export class AdminLoginDto {
  @IsEmail()
  email: string;

  @IsOptional()
  @IsString()
  @Matches(/^\d{6}$/, { message: 'OTP must be exactly 6 digits' })
  otp?: string;
}
