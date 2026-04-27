import { IsEmail, IsNotEmpty, IsString, Matches, MinLength } from 'class-validator';

export class VendorSelfRegisterDto {
  @IsString()
  @MinLength(2)
  business_name: string;

  @IsEmail()
  email: string;

  @IsString()
  @Matches(/^\+91[6-9]\d{9}$/, { message: 'phone must be in format +91XXXXXXXXXX' })
  phone: string;

  @IsString()
  @IsNotEmpty()
  category: string;
}
