import { Transform } from 'class-transformer';
import { IsArray, IsInt, IsOptional, IsString, IsUUID, Matches, Max, Min } from 'class-validator';
import { FORECAST_MAX_MONTHS } from './domain/forecast';

const list = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.split(',').filter(Boolean) : value);

export class ForecastQueryDto {
  @IsOptional() @Transform(({ value }) => (value === undefined ? value : Number(value)))
  @IsInt() @Min(1) @Max(FORECAST_MAX_MONTHS) months?: number;

  @IsOptional() @IsString() @Matches(/^[A-Z]{3}$/) currencyCode?: string;

  @IsOptional() @IsString() @Matches(/^-?\d{1,18}$/) startingBalanceMinor?: string;

  @IsOptional() @Transform(list) @IsArray() @IsUUID('all', { each: true }) excludeRuleIds?: string[];
}
