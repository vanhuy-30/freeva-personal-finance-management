import { Transform, Type } from 'class-transformer';
import {
  IsBoolean, IsIn, IsInt, IsOptional, IsString, IsUUID, Length, Matches, Max, Min, ValidateIf,
} from 'class-validator';
import { TRANSACTION_TYPES } from '../transactions/domain/transaction';
import { RECURRING_UNITS } from './domain/calendar';

const optional = (_: unknown, value: unknown) => value !== undefined;
const lower = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.toLowerCase() : value);
const upper = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.toUpperCase() : value);
const day = Matches(/^\d{4}-\d{2}-\d{2}$/);
const minor = Matches(/^-?[0-9]+$/);
const rate = Matches(/^\d{1,10}(?:\.\d{1,8})?$/);

export class CreateRecurringDto {
  @Transform(lower) @IsUUID() clientId!: string;
  @IsIn([...TRANSACTION_TYPES]) type!: typeof TRANSACTION_TYPES[number];
  @IsIn([...RECURRING_UNITS]) unit!: typeof RECURRING_UNITS[number];
  @Type(() => Number) @IsInt() @Min(1) @Max(366) interval!: number;
  @IsString() @Length(1, 20) @minor amountMinor!: string;
  @Transform(upper) @IsString() @Length(3, 3) currencyCode!: string;
  @Transform(lower) @IsUUID() accountId!: string;
  @ValidateIf(optional) @Transform(({ value }) => value === null ? null : typeof value === 'string' ? value.toLowerCase() : value)
  @IsUUID() categoryId?: string | null;
  @ValidateIf(optional) @Transform(({ value }) => value === null ? null : typeof value === 'string' ? value.toLowerCase() : value)
  @IsUUID() counterAccountId?: string | null;
  @ValidateIf(optional) @IsString() @Length(1, 20) @minor counterAmountMinor?: string | null;
  @ValidateIf(optional) @Transform(({ value }) => value === null ? null : typeof value === 'string' ? value.toUpperCase() : value)
  @IsString() @Length(3, 3) counterCurrencyCode?: string | null;
  @ValidateIf(optional) @IsString() @rate fxRate?: string | null;
  @IsString() @day startDate!: string;
  @ValidateIf(optional) @IsString() @day endDate?: string | null;
  @IsString() @day nextExecutionDate!: string;
  @ValidateIf(optional) @IsBoolean() active?: boolean;
}

export class UpdateRecurringDto {
  @IsInt() @Min(1) @Max(2147483646) version!: number;
  @ValidateIf(optional) @IsIn([...RECURRING_UNITS]) unit?: typeof RECURRING_UNITS[number];
  @ValidateIf(optional) @Type(() => Number) @IsInt() @Min(1) @Max(366) interval?: number;
  @ValidateIf(optional) @IsString() @Length(1, 20) @minor amountMinor?: string;
  @ValidateIf(optional) @Transform(upper) @IsString() @Length(3, 3) currencyCode?: string;
  @ValidateIf(optional) @Transform(lower) @IsUUID() accountId?: string;
  @ValidateIf(optional) @Transform(({ value }) => value === null ? null : typeof value === 'string' ? value.toLowerCase() : value)
  @IsUUID() categoryId?: string | null;
  @ValidateIf(optional) @Transform(({ value }) => value === null ? null : typeof value === 'string' ? value.toLowerCase() : value)
  @IsUUID() counterAccountId?: string | null;
  @ValidateIf(optional) @IsString() @Length(1, 20) @minor counterAmountMinor?: string | null;
  @ValidateIf(optional) @Transform(({ value }) => value === null ? null : typeof value === 'string' ? value.toUpperCase() : value)
  @IsString() @Length(3, 3) counterCurrencyCode?: string | null;
  @ValidateIf(optional) @IsString() @rate fxRate?: string | null;
  @ValidateIf(optional) @IsString() @day startDate?: string;
  @ValidateIf(optional) @IsString() @day endDate?: string | null;
  @ValidateIf(optional) @IsString() @day nextExecutionDate?: string;
  @ValidateIf(optional) @IsBoolean() active?: boolean;
}

export class RecurringQueryDto {
  @Type(() => Number) @IsInt() @Min(1) @Max(2147483647) page = 1;
  @Type(() => Number) @IsInt() @Min(1) @Max(100) pageSize = 50;
  @ValidateIf(optional) @Transform(({ value }) => value === 'true' ? true : value === 'false' ? false : value)
  @IsBoolean() active?: boolean;
}

export class RecurringIdDto {
  @Transform(lower) @IsUUID() id!: string;
}

export class DeleteRecurringDto {
  @Type(() => Number) @IsInt() @Min(1) @Max(2147483646) version!: number;
}
