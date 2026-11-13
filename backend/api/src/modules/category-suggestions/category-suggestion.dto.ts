import { Transform } from 'class-transformer';
import { IsIn, IsString, IsUUID, Matches, MaxLength, ValidateIf } from 'class-validator';
import { SUGGEST_SOURCES, SUGGEST_SURFACES } from './domain/category-suggestion';

const lower = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.toLowerCase() : value);

export class MappingIdDto {
  @Transform(lower) @IsUUID() id!: string;
}

const trim = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim() : value);
const optional = (_: object, value: unknown) => value !== undefined && value !== null;

/** BE-P5-E03: what the user typed so far. Merchant wins over the note when both are sent. */
export class SuggestCategoryDto {
  @ValidateIf(optional) @Transform(trim) @IsString() @MaxLength(200) merchant?: string | null;
  @ValidateIf(optional) @Transform(trim) @IsString() @MaxLength(2000) note?: string | null;
  @IsIn(['expense', 'income']) type!: 'expense' | 'income';
}

/** BE-P5-E03: sent once the transaction is saved after a suggestion was shown. */
export class SuggestionFeedbackDto {
  @ValidateIf(optional) @Transform(trim) @IsString() @MaxLength(200) merchant?: string | null;
  @Transform(lower) @IsUUID() suggestedCategoryId!: string;
  @Transform(lower) @IsUUID() chosenCategoryId!: string;
  @IsIn(SUGGEST_SOURCES) source!: (typeof SUGGEST_SOURCES)[number];
  @IsIn(SUGGEST_SURFACES) surface!: (typeof SUGGEST_SURFACES)[number];
}

export class SuggestionStatsQueryDto {
  @Matches(/^\d{4}-\d{2}-\d{2}$/) from!: string;
  @Matches(/^\d{4}-\d{2}-\d{2}$/) to!: string;
}
