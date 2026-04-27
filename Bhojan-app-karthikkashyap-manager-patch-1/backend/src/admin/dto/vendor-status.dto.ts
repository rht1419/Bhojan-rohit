import { IsString, MinLength, MaxLength } from 'class-validator';

export class VendorStatusDto {
  @IsString()
  @MinLength(3)
  @MaxLength(300)
  reason: string;
}

