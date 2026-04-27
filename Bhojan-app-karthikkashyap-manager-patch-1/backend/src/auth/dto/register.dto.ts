import { IsString, IsEmail, IsPhoneNumber, IsIn, IsOptional, MinLength, Matches, ValidateIf } from 'class-validator';

export class RegisterDto {
  @IsIn(['GUEST', 'EMPLOYEE'])
  user_type: 'GUEST' | 'EMPLOYEE';

  @IsString()
  @MinLength(2)
  full_name: string;

<<<<<<< HEAD
  @Matches(/^(\+91|91)?[6-9]\d{9}$/, { message: 'Phone must be a valid Indian mobile number' })
  phone: string;

  @Matches(/^(?=.*[A-Z])(?=.*\d)(?=.*[!@#$&*~]).{8,}$/, {
=======
  @Matches(/^\+91[6-9]\d{9}$/, { message: 'Phone must be in format +91XXXXXXXXXX' })
  phone: string;

  @Matches(/^(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&]).{8,}$/, {
>>>>>>> 9164b54b7ae96a96dfb046b32a6f1d92bc55e577
    message: 'Password must be at least 8 characters with 1 uppercase, 1 number, and 1 special character',
  })
  password: string;

  @ValidateIf((o: RegisterDto) => o.user_type === 'EMPLOYEE')
  @IsEmail()
  email?: string;

  @ValidateIf((o: RegisterDto) => o.user_type === 'EMPLOYEE')
  @IsString()
  @MinLength(1)
  employee_id?: string;
}
