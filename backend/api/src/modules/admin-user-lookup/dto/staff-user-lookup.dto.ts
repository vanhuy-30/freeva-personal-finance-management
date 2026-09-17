import { IsEmail, IsOptional, IsUUID } from 'class-validator';

export class StaffUserLookupDto {
  @IsOptional()
  @IsUUID()
  userId?: string;

  @IsOptional()
  @IsEmail()
  email?: string;
}
