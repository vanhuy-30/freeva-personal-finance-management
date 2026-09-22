import { Transform } from 'class-transformer';
import {
  IsEmail,
  IsString,
  Matches,
  MaxLength,
  MinLength,
} from 'class-validator';

export class EmailDto {
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim().toLowerCase() : value,
  )
  @IsEmail()
  @MaxLength(254)
  email!: string;
}

export class CredentialsDto extends EmailDto {
  @IsString()
  @MinLength(12)
  @MaxLength(128)
  password!: string;
}

export class TokenDto {
  @IsString()
  @Matches(/^[a-f0-9]{64}$/)
  token!: string;
}

export class ResetPasswordDto extends TokenDto {
  @IsString()
  @MinLength(12)
  @MaxLength(128)
  password!: string;
}
