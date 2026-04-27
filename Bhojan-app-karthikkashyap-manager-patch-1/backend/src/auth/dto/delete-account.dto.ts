import { IsOptional, IsString, Matches, MaxLength } from 'class-validator';

export class DeleteAccountDto {
  @IsOptional()
  @IsString()
  @Matches(/^\d{6}$/, { message: 'OTP must be exactly 6 digits' })
  otp?: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  reason?: string;
}
