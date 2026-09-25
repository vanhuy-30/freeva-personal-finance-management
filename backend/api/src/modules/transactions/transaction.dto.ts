import { Transform, Type } from 'class-transformer';
import { ArrayMaxSize, ArrayMinSize, ArrayUnique, IsArray, IsBoolean, IsISO8601, IsIn, IsInt, IsObject, IsString, IsUUID, Matches, Max, MaxLength, Min, ValidateIf, ValidateNested } from 'class-validator';
import { TRANSACTION_TYPES, type TransactionType } from './domain/transaction';
const optional = (_: unknown, value: unknown) => value !== undefined;
const nullable = (_: unknown, value: unknown) => value !== undefined && value !== null;
const uuid = ({ value }: { value: unknown }) => typeof value === 'string' ? value.toLowerCase() : value;
export class TransactionLegDto {
  @Transform(uuid) @IsUUID() clientId!: string;
  @Transform(uuid) @IsUUID() accountId!: string;
  @IsString() @Matches(/^[A-Z]{3}(?![\s\S])/) currencyCode!: string;
  @IsString() @MaxLength(20) @Matches(/^-?[0-9]+(?![\s\S])/) amountMinor!: string;
}
export class ManualFxDto {
  @IsString() @Matches(/^\d{1,10}(?:\.\d{1,8})?(?![\s\S])/) rate!: string;
  @IsString() @IsISO8601({ strict: true }) @Matches(/T.*(?:Z|[+-]\d{2}:\d{2})(?![\s\S])/) quotedAt!: string;
}
export class CreateTransactionDto {
  @IsIn(TRANSACTION_TYPES) type!: TransactionType;
  @IsString() @Matches(/^\d{4}-\d{2}-\d{2}(?![\s\S])/) occurredOn!: string;
  @IsArray() @ArrayMinSize(1) @ArrayMaxSize(2) @ValidateNested({ each: true }) @Type(() => TransactionLegDto) legs!: TransactionLegDto[];
  @ValidateIf(nullable) @Transform(uuid) @IsUUID() categoryId?: string | null;
  @ValidateIf(nullable) @IsString() @MaxLength(2000) notes?: string | null;
  @ValidateIf(optional) @IsArray() @ArrayMaxSize(20) @ArrayUnique() @IsUUID('all', { each: true }) tagIds?: string[];
  @ValidateIf(nullable) @IsObject() @ValidateNested() @Type(() => ManualFxDto) fx?: ManualFxDto | null;
}
export class UpdateTransactionDto {
  @IsInt() @Min(1) @Max(2147483646) version!: number;
  @ValidateIf(optional) @IsString() @Matches(/^\d{4}-\d{2}-\d{2}(?![\s\S])/) occurredOn?: string;
  @ValidateIf(optional) @IsArray() @ArrayMinSize(1) @ArrayMaxSize(2) @ValidateNested({ each: true }) @Type(() => TransactionLegDto) legs?: TransactionLegDto[];
  @ValidateIf(nullable) @Transform(uuid) @IsUUID() categoryId?: string | null;
  @ValidateIf(nullable) @IsString() @MaxLength(2000) notes?: string | null;
  @ValidateIf(optional) @IsArray() @ArrayMaxSize(20) @ArrayUnique() @IsUUID('all', { each: true }) tagIds?: string[];
  @ValidateIf(nullable) @IsObject() @ValidateNested() @Type(() => ManualFxDto) fx?: ManualFxDto | null;
  @ValidateIf(optional) @IsBoolean() deleted?: boolean;
}
export class TransactionIdDto { @Transform(uuid) @IsUUID() id!: string }
export class DeleteTransactionDto { @Type(() => Number) @IsInt() @Min(1) @Max(2147483646) version!: number }
export class TransactionQueryDto {
  @Type(() => Number) @IsInt() @Min(1) @Max(2147483647) page = 1;
  @Type(() => Number) @IsInt() @Min(1) @Max(100) pageSize = 50;
  @IsIn(['active', 'deleted', 'all']) status: 'active' | 'deleted' | 'all' = 'active';
  @ValidateIf(optional) @Transform(uuid) @IsUUID() accountId?: string;
  @ValidateIf(optional) @Transform(uuid) @IsUUID() categoryId?: string;
  @ValidateIf(optional) @IsIn(TRANSACTION_TYPES) type?: TransactionType;
  @ValidateIf(optional) @IsString() @Matches(/^\d{4}-\d{2}-\d{2}(?![\s\S])/) from?: string;
  @ValidateIf(optional) @IsString() @Matches(/^\d{4}-\d{2}-\d{2}(?![\s\S])/) to?: string;
  @ValidateIf(optional) @IsString() @MaxLength(200) search?: string;
}
