import { Transform } from 'class-transformer';
import {
  IsIn, IsInt, IsOptional, IsString, Matches, Max, MaxLength, Min,
} from 'class-validator';

export class UpdateProfileDto {
  /** Omitted keeps the stored name; blank clears it. */
  @IsOptional()
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() || null : value))
  @IsString()
  @MaxLength(60)
  displayName?: string | null;

  @IsIn(['vi', 'en'])
  locale!: string;

  @IsString()
  @Matches(/^[A-Z]{3}$/)
  defaultCurrencyCode!: string;

  @IsString()
  @MaxLength(100)
  timezone!: string;

  @IsInt()
  @Min(1)
  @Max(28)
  fiscalMonthStartDay!: number;

  @IsInt()
  @Min(1)
  @Max(2147483646)
  version!: number;
}
