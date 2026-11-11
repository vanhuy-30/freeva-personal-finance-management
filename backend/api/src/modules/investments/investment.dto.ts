import { Transform, Type } from 'class-transformer';
import {
  IsBoolean, IsIn, IsInt, IsISO8601, IsObject, IsString, IsUUID, Length, Matches, Max, MaxLength, Min, ValidateIf, ValidateNested,
} from 'class-validator';
import { INVESTMENT_KINDS, INVESTMENT_SIDES } from './domain/investment';

const optional = (_: unknown, value: unknown) => value !== undefined;
/** Required key that may be null: undefined fails, null skips the other checks. */
const presentOrNull = (_: unknown, value: unknown) => value !== null;
const nullable = (_: unknown, value: unknown) => value !== undefined && value !== null;
const lower = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.toLowerCase() : value);
const upper = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.toUpperCase() : value);
const trim = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim() : value);
const day = Matches(/^\d{4}-\d{2}-\d{2}(?![\s\S])/);
const positiveMinor = Matches(/^[1-9][0-9]{0,18}(?![\s\S])/);
const nonNegativeMinor = Matches(/^(0|[1-9][0-9]{0,18})(?![\s\S])/);
const quantity = Matches(/^\d{1,20}(\.\d{1,8})?(?![\s\S])/);
const version = [Type(() => Number), IsInt(), Min(1), Max(2147483646)];
const applyAll = (decorators: PropertyDecorator[]) => (target: object, key: string) => {
  for (const decorator of decorators) decorator(target, key);
};

/** First buy booked with the position (BE-P4-E03). */
export class InitialTradeDto {
  @Transform(lower) @IsUUID() clientId!: string;
  /** Decimal string, up to 8 decimals. Deposits and property use "1". */
  @IsString() @quantity quantity!: string;
  /** Total money of the buy, minor units. Give this or `priceMinor`. */
  @ValidateIf(optional) @IsString() @positiveMinor amountMinor?: string;
  /** Price of one unit, minor units; also becomes the latest price when a wallet paid. */
  @ValidateIf(optional) @IsString() @positiveMinor priceMinor?: string;
  /** Wallet that paid; null = already owned before using the app (no wallet leg). */
  @ValidateIf(presentOrNull) @Transform(lower) @IsUUID() accountId!: string | null;
  @IsString() @day tradedOn!: string;
  @ValidateIf(nullable) @IsString() @MaxLength(500) note?: string | null;
}

export class CreateInvestmentDto {
  @Transform(lower) @IsUUID() clientId!: string;
  @IsIn([...INVESTMENT_KINDS]) kind!: (typeof INVESTMENT_KINDS)[number];
  @Transform(trim) @IsString() @Length(1, 80) name!: string;
  @Transform(upper) @IsString() @Matches(/^[A-Z]{3}(?![\s\S])/) currencyCode!: string;
  /** chi | luong (gold), share, unit, coin, deposit, property. */
  @IsString() @Length(1, 16) unit!: string;
  /** Savings deposit only: annual simple rate in basis points (600 = 6%). */
  @ValidateIf(nullable) @Type(() => Number) @IsInt() @Min(0) @Max(100000) interestRateBps?: number | null;
  @ValidateIf(nullable) @IsString() @day startDate?: string | null;
  @ValidateIf(nullable) @IsString() @day maturityDate?: string | null;
  @ValidateIf(nullable) @IsString() @MaxLength(500) note?: string | null;
  @ValidateIf(nullable) @IsObject() @ValidateNested() @Type(() => InitialTradeDto) initialTrade?: InitialTradeDto | null;
}

export class UpdateInvestmentDto {
  @applyAll(version) version!: number;
  @ValidateIf(optional) @Transform(trim) @IsString() @Length(1, 80) name?: string;
  @ValidateIf(nullable) @IsString() @MaxLength(500) note?: string | null;
  @ValidateIf(nullable) @IsString() @day maturityDate?: string | null;
}

export class ArchiveInvestmentDto {
  @applyAll(version) version!: number;
}

export class ListInvestmentsDto {
  @ValidateIf(optional)
  @Transform(({ value }) => value === 'true' || value === true)
  @IsBoolean()
  includeArchived?: boolean;
  @ValidateIf(optional) @IsIn([...INVESTMENT_KINDS]) kind?: (typeof INVESTMENT_KINDS)[number];
}

export class TradeInvestmentDto {
  @Transform(lower) @IsUUID() clientId!: string;
  @IsIn([...INVESTMENT_SIDES]) side!: (typeof INVESTMENT_SIDES)[number];
  /** Decimal string, up to 8 decimals. Deposits and property use "1". */
  @IsString() @quantity quantity!: string;
  /** Money out of the wallet (buy) or into it (sell), minor units. Give this or `priceMinor`. */
  @ValidateIf(optional) @IsString() @positiveMinor amountMinor?: string;
  /** Price of one unit, minor units; also becomes the latest price when a wallet is used. */
  @ValidateIf(optional) @IsString() @positiveMinor priceMinor?: string;
  /** Null only on a buy the user already owned (no wallet leg). */
  @ValidateIf(presentOrNull) @Transform(lower) @IsUUID() accountId!: string | null;
  @IsString() @day tradedOn!: string;
  @ValidateIf(nullable) @IsString() @MaxLength(500) note?: string | null;
}

/** Edit of one buy; `version` is the position's. */
export class UpdateInvestmentTradeDto {
  @applyAll(version) version!: number;
  @ValidateIf(optional) @IsString() @quantity quantity?: string;
  @ValidateIf(optional) @IsString() @positiveMinor amountMinor?: string;
  @ValidateIf(optional) @IsString() @positiveMinor priceMinor?: string;
  @ValidateIf(nullable) @Transform(lower) @IsUUID() accountId?: string | null;
  @ValidateIf(optional) @IsString() @day tradedOn?: string;
  @ValidateIf(nullable) @IsString() @MaxLength(500) note?: string | null;
}

export class DeleteInvestmentTradeDto {
  @applyAll(version) version!: number;
}

export class AddInvestmentPriceDto {
  @Transform(lower) @IsUUID() clientId!: string;
  /** Price of one unit, minor units. */
  @IsString() @nonNegativeMinor priceMinor!: string;
  @IsISO8601({ strict: true }) quotedAt!: string;
}
