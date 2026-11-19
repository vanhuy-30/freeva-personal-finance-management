import { Transform, Type } from 'class-transformer';
import {
  ArrayMaxSize, ArrayUnique, IsArray, IsBoolean, IsIn, IsInt, IsObject, IsOptional, IsString, Matches, Max, MaxLength, Min,
  ValidateIf, ValidateNested,
} from 'class-validator';

/** BE-P6-002: first-run goals, in the order the question shows them. */
export const ONBOARDING_GOALS = ['track', 'budget', 'save', 'debt', 'assets', 'habits'] as const;

/**
 * BE-P6-002: declared income band, integer minor units of the default currency as strings.
 * `maxMinor` null is the open top band. Cross-field rules (max >= min, open band needs min > 0) are checked in the service.
 */
export class DeclaredIncomeDto {
  @IsString()
  @Matches(/^(0|[1-9][0-9]{0,17})$/)
  minMinor!: string;

  @ValidateIf((_, value) => value !== null)
  @IsString()
  @Matches(/^[1-9][0-9]{0,17}$/)
  maxMinor!: string | null;
}

/** Answers from the first-run questions (BE-P3-012). Every field is optional: a skipped step sends nothing. */
export class OnboardingAnswersDto {
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(ONBOARDING_GOALS.length)
  @ArrayUnique()
  @IsIn(ONBOARDING_GOALS, { each: true })
  goals?: string[];

  /** Declared income band; omitted keeps the stored one. Null is refused here: clearing is PUT /profile/declared-income. */
  @ValidateIf((_, value) => value !== undefined)
  @IsObject()
  @ValidateNested()
  @Type(() => DeclaredIncomeDto)
  declaredIncome?: DeclaredIncomeDto;
}

/** BE-P6-002: `null` clears the declared income. */
export class DeclaredIncomeUpdateDto {
  @ValidateIf((_, value) => value !== null)
  @IsObject()
  @ValidateNested()
  @Type(() => DeclaredIncomeDto)
  declaredIncome!: DeclaredIncomeDto | null;
}

/** `null` goes back to the default currency of the profile. */
export class DisplayCurrencyDto {
  @ValidateIf((_, value) => value !== null)
  @IsString()
  @Matches(/^[A-Z]{3}$/)
  currencyCode!: string | null;
}

/** PRD-P5-E01: switch for category suggestions, insights and spending forecast. */
export class AutoSuggestDto {
  @IsBoolean()
  enabled!: boolean;
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
