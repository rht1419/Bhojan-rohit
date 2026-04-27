import { IsString, IsUUID, Matches } from 'class-validator';

export class VendorActivateDto {
  @IsUUID()
  activation_token: string;

  @IsString()
  @Matches(/^(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]).{8,}$/, {
    message: 'Password must be min 8 chars with 1 uppercase, 1 number, 1 special character',
  })
  password: string;
}
