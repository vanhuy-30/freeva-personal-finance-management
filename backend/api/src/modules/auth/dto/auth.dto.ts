import { Transform, Type } from 'class-transformer';
import {
  Equals,
  IsEmail,
  IsIn,
  IsOptional,
  IsString,
  IsUUID,
  Matches,
  MaxLength,
  MinLength,
  ValidateNested,
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

const trimmed = ({ value }: { value: unknown }) =>
  typeof value === 'string' ? value.trim() || null : value;

/**
 * The phone signing in (BE-P6-001). [id] is made once by the app; a new sign-in
 * with the same id ends that phone's previous session. [name] is the model
 * ("iPhone 15 Pro"), never the name the person gave the phone.
 */
export class SessionDeviceDto {
  @IsUUID()
  id!: string;

  @IsOptional()
  @Transform(trimmed)
  @IsString()
  @MaxLength(80)
  name!: string | null;

  @IsIn(['ios', 'android'])
  platform!: 'ios' | 'android';

  @IsOptional()
  @Transform(trimmed)
  @IsString()
  @MaxLength(32)
  osVersion!: string | null;
}

export class CredentialsDto extends EmailDto {
  @IsString()
  @MinLength(8)
  @MaxLength(128)
  password!: string;

  @IsOptional()
  @ValidateNested()
  @Type(() => SessionDeviceDto)
  device?: SessionDeviceDto;
}

export class NewCredentialsDto extends EmailDto {
  @IsString()
  @MinLength(8)
  @MaxLength(128)
  @Matches(LETTER_AND_DIGIT)
  password!: string;
}

/** Email sign-up: the person must tick the Terms and Privacy checkbox (DS-P2-004). */
export class RegisterDto extends NewCredentialsDto {
  @Equals(true)
  termsAccepted!: true;
}

export class TokenDto {
  @IsString()
  @Matches(/^[a-f0-9]{64}$/)
  token!: string;
}

export class ResetPasswordDto extends TokenDto {
  @IsString()
  @MinLength(8)
  @MaxLength(128)
  @Matches(LETTER_AND_DIGIT)
  password!: string;
}

/** Signed-in password change: the current password proves it is the owner. */
export class ChangePasswordDto {
  @IsString()
  @MinLength(1)
  @MaxLength(128)
  currentPassword!: string;

  @IsString()
  @MinLength(8)
  @MaxLength(128)
  @Matches(LETTER_AND_DIGIT)
  newPassword!: string;
}

/** Step-up for account delete/export (SEC-P6-002). Omitted only by accounts without a password. */
export class ConfirmIdentityDto {
  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(128)
  password?: string;
}
