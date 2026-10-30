import { IsIn, IsOptional, IsString, Matches, ValidateIf } from 'class-validator';
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

/** IsOptional (not ValidateIf) so whitelist/forbidNonWhitelisted see the property. */
export class MonthReviewQueryDto {
  @IsOptional() @IsString() @Matches(/^\d{4}-\d{2}-\d{2}(?![\s\S])/) on?: string;
}
