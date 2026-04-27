import { IsString, IsEmail, IsOptional, Matches, MinLength } from 'class-validator';

export class UpgradeEmployeeDto {
  @IsString()
  @MinLength(1)
  employee_id: string;

  @IsEmail()
  work_email: string;

  @IsOptional()
  @IsString()
  @Matches(/^\d{6}$/, { message: 'OTP must be exactly 6 digits' })
  otp?: string;
}
