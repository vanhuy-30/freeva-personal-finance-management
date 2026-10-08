import { Transform, Type } from 'class-transformer';
import {
  IsBoolean, IsIn, IsInt, IsString, IsUUID, Length, Matches, Max, MaxLength, Min, ValidateIf,
} from 'class-validator';
import { ACCOUNT_TYPES, type AccountType } from './domain/financial-account';

const optional = (_: unknown, value: unknown) => value !== undefined;
const nullable = (_: unknown, value: unknown) => value !== undefined && value !== null;
const trim = ({ value }: { value: unknown }) => typeof value === 'string' ? value.trim() : value;

export class CreateAccountDto {
  @IsUUID() clientId!: string;
  @Transform(trim) @IsString() @Length(1, 100) name!: string;
  @IsIn(ACCOUNT_TYPES) type!: AccountType;
  @IsString() @Matches(/^[A-Z]{3}(?![\s\S])/) currencyCode!: string;
  @IsString() @MaxLength(20) @Matches(/^-?[0-9]+(?![\s\S])/) initialBalanceMinor!: string;
  @ValidateIf(optional) @IsInt() @Min(0) @Max(2147483647) sortOrder?: number;
  @ValidateIf(nullable) @IsString() @MaxLength(20) @Matches(/^-?[0-9]+(?![\s\S])/) creditLimitMinor?: string | null;
  @ValidateIf(nullable) @IsInt() @Min(1) @Max(28) statementCloseDay?: number | null;
  @ValidateIf(nullable) @IsInt() @Min(1) @Max(28) paymentDueDay?: number | null;
}
export class UpdateAccountDto {
  @IsInt() @Min(1) @Max(2147483646) version!: number;
  @ValidateIf(optional) @Transform(trim) @IsString() @Length(1, 100) name?: string;
  @ValidateIf(optional) @IsIn(ACCOUNT_TYPES) type?: AccountType;
  @ValidateIf(optional) @IsString() @Matches(/^[A-Z]{3}(?![\s\S])/) currencyCode?: string;
  @ValidateIf(optional) @IsString() @MaxLength(20) @Matches(/^-?[0-9]+(?![\s\S])/) initialBalanceMinor?: string;
  @ValidateIf(optional) @IsInt() @Min(0) @Max(2147483647) sortOrder?: number;
  @ValidateIf(nullable) @IsString() @MaxLength(20) @Matches(/^-?[0-9]+(?![\s\S])/) creditLimitMinor?: string | null;
  @ValidateIf(nullable) @IsInt() @Min(1) @Max(28) statementCloseDay?: number | null;
  @ValidateIf(nullable) @IsInt() @Min(1) @Max(28) paymentDueDay?: number | null;
  @ValidateIf(optional) @IsBoolean() archived?: boolean;
}
export class AccountQueryDto {
  @Type(() => Number) @IsInt() @Min(1) @Max(2147483647) page = 1;
  @Type(() => Number) @IsInt() @Min(1) @Max(100) pageSize = 50;
  @IsIn(['active', 'archived', 'all']) status: 'active' | 'archived' | 'all' = 'active';
}
export class ArchiveAccountDto {
  @Type(() => Number) @IsInt() @Min(1) @Max(2147483646) version!: number;
}
export class AccountIdDto {
  @IsUUID() id!: string;
}
