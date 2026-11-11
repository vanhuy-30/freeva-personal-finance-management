import { Transform, Type } from 'class-transformer';
import { IsBoolean, IsIn, IsObject, IsString, IsUUID, MaxLength, ValidateIf, ValidateNested } from 'class-validator';
import { IMPORT_PRESETS } from './domain/import-format';

const optional = (_: unknown, value: unknown) => value !== undefined;
const lower = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.toLowerCase() : value);
const header = () => [ValidateIf(optional), IsString(), MaxLength(100)];
const apply = (...decorators: PropertyDecorator[]) => (target: object, key: string) => decorators.forEach(decorator => decorator(target, key));

/** Source header name per Freeva field; overrides the preset's aliases. */
export class ImportMappingDto {
  @apply(...header()) date?: string;
  @apply(...header()) time?: string;
  @apply(...header()) type?: string;
  @apply(...header()) amount?: string;
  @apply(...header()) currency?: string;
  @apply(...header()) wallet?: string;
  @apply(...header()) category?: string;
  @apply(...header()) merchant?: string;
  @apply(...header()) notes?: string;
  @apply(...header()) id?: string;
}

export class PreviewImportDto {
  /** The CSV file's text (UTF-8, BOM allowed). */
  @IsString() @MaxLength(1_000_000) text!: string;
  @ValidateIf(optional) @IsIn(IMPORT_PRESETS) preset?: (typeof IMPORT_PRESETS)[number];
  @ValidateIf(optional) @IsIn(['iso', 'dmy', 'mdy']) dateFormat?: 'iso' | 'dmy' | 'mdy';
  @ValidateIf(optional) @IsIn(['plain', 'dot_thousands', 'comma_thousands']) numberFormat?: 'plain' | 'dot_thousands' | 'comma_thousands';
  @ValidateIf(optional) @ValidateNested() @Type(() => ImportMappingDto) mapping?: ImportMappingDto;
  /** Source wallet name → Freeva account id. */
  @ValidateIf(optional) @IsObject() walletMap?: Record<string, string>;
  /** Source category name → Freeva category id (`null` = no category, income only). */
  @ValidateIf(optional) @IsObject() categoryMap?: Record<string, string | null>;
  /** Used for rows without a wallet column/value. */
  @ValidateIf(optional) @Transform(lower) @IsUUID() defaultAccountId?: string;
  /**
   * BE-P5-E03: rows with an empty category, by merchant (matched ignoring case and accents) → category id.
   * "Áp dụng cho N khoản ở đây" in the sheet.
   */
  @ValidateIf(optional) @IsObject() merchantCategoryMap?: Record<string, string>;
  /** BE-P5-E03: one row with an empty category, by file row number → category id. Wins over the merchant map. */
  @ValidateIf(optional) @IsObject() rowCategoryMap?: Record<string, string>;
}

export class CommitImportDto extends PreviewImportDto {
  @Transform(lower) @IsUUID() batchClientId!: string;
  /** Default false: rows already in the ledger are skipped, never overwritten. */
  @ValidateIf(optional) @IsBoolean() includeDuplicates?: boolean;
}
