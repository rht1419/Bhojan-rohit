import { IsString, Matches } from 'class-validator';

export class LoginDto {
<<<<<<< HEAD
  @Matches(/^(\+91|91)?[6-9]\d{9}$/, { message: 'Phone must be a valid Indian mobile number' })
=======
  @Matches(/^\+91[6-9]\d{9}$/, { message: 'Phone must be in format +91XXXXXXXXXX' })
>>>>>>> 9164b54b7ae96a96dfb046b32a6f1d92bc55e577
  phone: string;

  @IsString()
  password: string;
}
