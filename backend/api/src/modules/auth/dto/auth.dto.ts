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

/**
 * A new password needs at least one letter and one digit, in any script
 * (DS-P2-004). Symbols are only a strength tip. Login keeps the length rule
 * alone, so passwords set before this rule still work.
 */
export const LETTER_AND_DIGIT = /^(?=[\s\S]*\p{L})(?=[\s\S]*\p{Nd})[\s\S]*$/u;

export class CredentialsDto extends EmailDto {
  @IsString()
  @MinLength(12)
  @MaxLength(128)
  password!: string;
}

export class NewCredentialsDto extends EmailDto {
  @IsString()
  @MinLength(12)
  @MaxLength(128)
  @Matches(LETTER_AND_DIGIT)
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
  @Matches(LETTER_AND_DIGIT)
  password!: string;
}
