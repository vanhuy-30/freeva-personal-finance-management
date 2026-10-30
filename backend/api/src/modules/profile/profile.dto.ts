import { Transform } from 'class-transformer';
import {
  ArrayMaxSize, ArrayUnique, IsArray, IsIn, IsInt, IsOptional, IsString, Matches, Max, MaxLength, Min,
} from 'class-validator';

export const ONBOARDING_GOALS = ['track', 'save', 'budget', 'debt', 'emergency', 'understand'] as const;
export const TRACKING_HABITS = ['manual', 'spreadsheet', 'app', 'none'] as const;
export const REVIEW_CADENCES = ['daily', 'weekly', 'monthly', 'rarely'] as const;

/** Answers from the first-run questions (DS-P2-004). Every field is optional: a skipped step sends nothing. */
export class OnboardingAnswersDto {
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(2)
  @ArrayUnique()
  @IsIn(ONBOARDING_GOALS, { each: true })
  goals?: string[];

  @IsOptional()
  @IsIn(TRACKING_HABITS)
  trackingHabit?: string;

  @IsOptional()
  @IsIn(REVIEW_CADENCES)
  reviewCadence?: string;

  /** First monthly budget, positive integer minor units of the default currency. */
  @IsOptional()
  @IsString()
  @Matches(/^[1-9][0-9]{0,17}$/)
  budgetMinor?: string;
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
