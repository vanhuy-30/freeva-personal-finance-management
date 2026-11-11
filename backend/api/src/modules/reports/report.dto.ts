import { Transform } from 'class-transformer';
import { IsIn, IsOptional, IsString, IsUUID, Matches, ValidateIf } from 'class-validator';
import { INVESTMENT_KINDS, type InvestmentKind } from '../investments/domain/investment';
import { REPORT_PERIODS, SERIES_WINDOWS, TREND_PERIODS, type ReportPeriodKind, type SeriesWindow, type TrendPeriodKind } from './domain/report';

const optional = (_: unknown, value: unknown) => value !== undefined;

/** Optional currency the response also converts into (BE-P2-013). Display only. */
export class NetWorthQueryDto {
  @IsOptional() @IsString() @Matches(/^[A-Z]{3}$/) displayCurrency?: string;
}

export class CashflowQueryDto {
  @IsIn(REPORT_PERIODS) period!: ReportPeriodKind;
  @ValidateIf(optional) @IsString() @Matches(/^\d{4}-\d{2}-\d{2}(?![\s\S])/) on?: string;
  @ValidateIf(optional) @IsString() @Matches(/^\d{4}-\d{2}-\d{2}(?![\s\S])/) from?: string;
  @ValidateIf(optional) @IsString() @Matches(/^\d{4}-\d{2}-\d{2}(?![\s\S])/) to?: string;
  @IsOptional() @IsString() @Matches(/^[A-Z]{3}$/) displayCurrency?: string;
}

export class TrendQueryDto {
  @IsIn(TREND_PERIODS) period!: TrendPeriodKind;
  @ValidateIf(optional) @IsString() @Matches(/^\d{4}-\d{2}-\d{2}(?![\s\S])/) on?: string;
}

export class SeriesQueryDto {
  @IsIn(SERIES_WINDOWS) window!: SeriesWindow;
  @ValidateIf(optional) @IsString() @Matches(/^\d{4}-\d{2}-\d{2}(?![\s\S])/) on?: string;
}

/** Value of held investments over time (BE-P4-E03); narrow to one kind or one position. */
export class InvestmentHistoryQueryDto extends SeriesQueryDto {
  @IsOptional() @IsIn([...INVESTMENT_KINDS]) kind?: InvestmentKind;
  @IsOptional() @Transform(({ value }: { value: unknown }) => (typeof value === 'string' ? value.toLowerCase() : value)) @IsUUID() investmentId?: string;
}

/** IsOptional (not ValidateIf) so whitelist/forbidNonWhitelisted see the property. */
export class MonthReviewQueryDto {
  @IsOptional() @IsString() @Matches(/^\d{4}-\d{2}-\d{2}(?![\s\S])/) on?: string;
}
