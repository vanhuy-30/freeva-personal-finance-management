import { Transform, Type } from 'class-transformer';
import { IsBoolean, IsIn, IsInt, IsString, IsUUID, Length, Matches, Max, MaxLength, Min, ValidateIf } from 'class-validator';
import { PERSONAL_DEBT_DIRECTIONS } from './domain/personal-debt';

const optional = (_: unknown, value: unknown) => value !== undefined;
const nullable = (_: unknown, value: unknown) => value !== undefined && value !== null;
const lower = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.toLowerCase() : value);
const trim = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim() : value);
const day = Matches(/^\d{4}-\d{2}-\d{2}(?![\s\S])/);
const positiveMinor = Matches(/^[1-9][0-9]{0,18}(?![\s\S])/);
const version = [Type(() => Number), IsInt(), Min(1), Max(2147483646)];
const applyAll = (decorators: PropertyDecorator[]) => (target: object, key: string) => {
  for (const decorator of decorators) decorator(target, key);
};

export class CreatePersonalDebtDto {
  @Transform(lower) @IsUUID() clientId!: string;
  @IsIn([...PERSONAL_DEBT_DIRECTIONS]) direction!: (typeof PERSONAL_DEBT_DIRECTIONS)[number];
  @Transform(trim) @IsString() @Length(1, 80) counterparty!: string;
  @IsString() @positiveMinor amountMinor!: string;
  /** Wallet the money leaves (lent) or enters (borrowed); its currency is the debt's currency. */
  @Transform(lower) @IsUUID() accountId!: string;
  @IsString() @day occurredOn!: string;
  @ValidateIf(nullable) @IsString() @day dueDate?: string | null;
  @ValidateIf(nullable) @IsString() @MaxLength(500) note?: string | null;
}

export class UpdatePersonalDebtDto {
  @applyAll(version) version!: number;
  @ValidateIf(optional) @Transform(trim) @IsString() @Length(1, 80) counterparty?: string;
  @ValidateIf(nullable) @IsString() @day dueDate?: string | null;
  @ValidateIf(nullable) @IsString() @MaxLength(500) note?: string | null;
}

export class ArchivePersonalDebtDto {
  @applyAll(version) version!: number;
}

export class ListPersonalDebtsDto {
  @ValidateIf(optional)
  @Transform(({ value }) => value === 'true' || value === true)
  @IsBoolean()
  includeArchived?: boolean;
}

export class PayPersonalDebtDto {
  @Transform(lower) @IsUUID() clientId!: string;
  @IsString() @positiveMinor amountMinor!: string;
  /** Wallet that receives (lent) or pays (borrowed); defaults to the wallet of the debt. */
  @ValidateIf(nullable) @Transform(lower) @IsUUID() accountId?: string | null;
  @IsString() @day paidOn!: string;
}
