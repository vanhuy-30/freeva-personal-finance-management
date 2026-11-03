import { Transform } from 'class-transformer';
import {
  ArrayMaxSize, ArrayUnique, IsArray, IsIn, IsInt, IsOptional, IsString, Matches, Max, MaxLength, Min, ValidateIf,
} from 'class-validator';

export const ONBOARDING_GOALS = ['track', 'save', 'budget'] as const;

/** Answers from the first-run questions (BE-P3-012). Every field is optional: a skipped step sends nothing. */
export class OnboardingAnswersDto {
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(2)
  @ArrayUnique()
  @IsIn(ONBOARDING_GOALS, { each: true })
  goals?: string[];

  /** Monthly income, positive integer minor units of the default currency. */
  @IsOptional()
  @IsString()
  @Matches(/^[1-9][0-9]{0,17}$/)
  monthlyIncomeMinor?: string;
}

/** `null` clears the income. */
export class MonthlyIncomeDto {
  @ValidateIf((_, value) => value !== null)
  @IsString()
  @Matches(/^[1-9][0-9]{0,17}$/)
  monthlyIncomeMinor!: string | null;
}

/** `null` goes back to the default currency of the profile. */
export class DisplayCurrencyDto {
  @ValidateIf((_, value) => value !== null)
  @IsString()
  @Matches(/^[A-Z]{3}$/)
  currencyCode!: string | null;
}

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
