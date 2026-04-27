import { IsString, Matches } from 'class-validator';

export class PasswordResetVerifyDto {
<<<<<<< HEAD
  @Matches(/^(\+91|91)?[6-9]\d{9}$/, { message: 'Phone must be a valid Indian mobile number' })
=======
  @Matches(/^\+91[6-9]\d{9}$/, { message: 'Phone must be a valid Indian mobile number (+91XXXXXXXXXX)' })
>>>>>>> 9164b54b7ae96a96dfb046b32a6f1d92bc55e577
  phone: string;

  @IsString()
  @Matches(/^\d{6}$/, { message: 'OTP must be exactly 6 digits' })
  otp: string;

  @IsString()
  @Matches(/^(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>/?]).{8,}$/, {
    message: 'Password must be at least 8 characters with 1 uppercase, 1 number, and 1 special character',
  })
  new_password: string;
}
