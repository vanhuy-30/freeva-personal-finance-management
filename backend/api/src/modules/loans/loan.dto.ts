import { Transform, Type } from 'class-transformer';
import { IsBoolean, IsIn, IsInt, IsString, IsUUID, Length, Matches, Max, Min, ValidateIf } from 'class-validator';
import { LOAN_FREQUENCIES, LOAN_KINDS, MAX_RATE_BPS } from './domain/loan';

const optional = (_: unknown, value: unknown) => value !== undefined;
const nullable = (_: unknown, value: unknown) => value !== undefined && value !== null;
const lower = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.toLowerCase() : value);
const trim = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim() : value);
const day = Matches(/^\d{4}-\d{2}-\d{2}(?![\s\S])/);
const positiveMinor = Matches(/^[1-9][0-9]{0,18}(?![\s\S])/);
const nonNegativeMinor = Matches(/^(0|[1-9][0-9]{0,18})(?![\s\S])/);
const version = [Type(() => Number), IsInt(), Min(1), Max(2147483646)];
const applyAll = (decorators: PropertyDecorator[]) => (target: object, key: string) => {
  for (const decorator of decorators) decorator(target, key);
};

export class CreateLoanDto {
  @Transform(lower) @IsUUID() clientId!: string;
  @IsIn([...LOAN_KINDS]) kind!: (typeof LOAN_KINDS)[number];
  @Transform(trim) @IsString() @Length(1, 80) name!: string;
  @Transform(({ value }) => (typeof value === 'string' ? value.toUpperCase() : value)) @IsString() @Matches(/^[A-Z]{3}$/) currencyCode!: string;
  @IsString() @positiveMinor principalMinor!: string;
  /** Defaults to the principal. */
  @ValidateIf(optional) @IsString() @nonNegativeMinor outstandingMinor?: string;
  @Type(() => Number) @IsInt() @Min(0) @Max(MAX_RATE_BPS) interestRateBps!: number;
  @ValidateIf(nullable) @IsString() @nonNegativeMinor installmentMinor?: string | null;
  @IsIn([...LOAN_FREQUENCIES]) frequency!: (typeof LOAN_FREQUENCIES)[number];
  @IsString() @day startDate!: string;
  @ValidateIf(nullable) @IsString() @day endDate?: string | null;
  @ValidateIf(nullable) @IsString() @day nextDueDate?: string | null;
  @ValidateIf(nullable) @Transform(lower) @IsUUID() accountId?: string | null;
}

export class UpdateLoanDto {
  @applyAll(version) version!: number;
  @ValidateIf(optional) @IsIn([...LOAN_KINDS]) kind?: (typeof LOAN_KINDS)[number];
  @ValidateIf(optional) @Transform(trim) @IsString() @Length(1, 80) name?: string;
  @ValidateIf(optional) @Type(() => Number) @IsInt() @Min(0) @Max(MAX_RATE_BPS) interestRateBps?: number;
  @ValidateIf(nullable) @IsString() @nonNegativeMinor installmentMinor?: string | null;
  @ValidateIf(optional) @IsIn([...LOAN_FREQUENCIES]) frequency?: (typeof LOAN_FREQUENCIES)[number];
  @ValidateIf(nullable) @IsString() @day endDate?: string | null;
  @ValidateIf(nullable) @IsString() @day nextDueDate?: string | null;
  @ValidateIf(nullable) @Transform(lower) @IsUUID() accountId?: string | null;
}

export class ArchiveLoanDto {
  @applyAll(version) version!: number;
}

export class ListLoansDto {
  @ValidateIf(optional)
  @Transform(({ value }) => value === 'true' || value === true)
  @IsBoolean()
  includeArchived?: boolean;
}

export class PayLoanDto {
  @Transform(lower) @IsUUID() clientId!: string;
  @IsString() @positiveMinor amountMinor!: string;
  /** Wallet the payment leaves; defaults to the loan's linked wallet. */
  @ValidateIf(nullable) @Transform(lower) @IsUUID() accountId?: string | null;
  /** Both or neither; omit to split automatically (interest of the period first). */
  @ValidateIf(nullable) @IsString() @nonNegativeMinor principalMinor?: string | null;
  @ValidateIf(nullable) @IsString() @nonNegativeMinor interestMinor?: string | null;
  @ValidateIf(nullable) @Transform(lower) @IsUUID() principalCategoryId?: string | null;
  @ValidateIf(nullable) @Transform(lower) @IsUUID() interestCategoryId?: string | null;
  @IsString() @day paidOn!: string;
}

export class AdjustLoanDto {
  @IsString() @nonNegativeMinor outstandingMinor!: string;
  @applyAll(version) version!: number;
}
