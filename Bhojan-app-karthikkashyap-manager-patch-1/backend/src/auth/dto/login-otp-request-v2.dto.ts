import { IsNotEmpty, IsString, Matches } from 'class-validator';

export class LoginOtpRequestV2Dto {
  @IsNotEmpty()
  @IsString()
  @Matches(/^(\+91|91)?[6-9]\d{9}$/, { message: 'Phone must be a valid Indian mobile number' })
  phone: string;
}

