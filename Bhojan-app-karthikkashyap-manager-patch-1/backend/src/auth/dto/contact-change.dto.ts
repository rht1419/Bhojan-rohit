import { IsEnum, IsString, MinLength } from 'class-validator';
import { ContactType } from '@prisma/client';

export class ContactChangeDto {
  @IsEnum(ContactType)
  type: ContactType;

  @IsString()
  @MinLength(1)
  new_value: string;
}
