import { IsIn, IsString, Matches, ValidateIf } from 'class-validator';
import { REPORT_PERIODS, type ReportPeriodKind } from './domain/report';

const optional = (_: unknown, value: unknown) => value !== undefined;

export class CashflowQueryDto {
  @IsIn(REPORT_PERIODS) period!: ReportPeriodKind;
  @ValidateIf(optional) @IsString() @Matches(/^\d{4}-\d{2}-\d{2}(?![\s\S])/) on?: string;
  @ValidateIf(optional) @IsString() @Matches(/^\d{4}-\d{2}-\d{2}(?![\s\S])/) from?: string;
  @ValidateIf(optional) @IsString() @Matches(/^\d{4}-\d{2}-\d{2}(?![\s\S])/) to?: string;
}
