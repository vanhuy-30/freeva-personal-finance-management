import { Transform, Type } from 'class-transformer';
import { IsIn, IsInt, IsString, IsUUID, Matches, Max, Min, ValidateIf } from 'class-validator';
import { MAX_INSTALLMENTS, MIN_INSTALLMENTS } from './domain/card-installment';

const optional = (_: unknown, value: unknown) => value !== undefined;
const nullable = (_: unknown, value: unknown) => value !== undefined && value !== null;
const lower = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.toLowerCase() : value);
const day = Matches(/^\d{4}-\d{2}-\d{2}(?![\s\S])/);
const positiveMinor = Matches(/^[1-9][0-9]{0,18}(?![\s\S])/);

export class CreateCardInstallmentDto {
  @Transform(lower) @IsUUID() clientId!: string;
  /** The expense on a credit wallet that becomes a schedule. */
  @Transform(lower) @IsUUID() transactionId!: string;
  @Type(() => Number) @IsInt() @Min(MIN_INSTALLMENTS) @Max(MAX_INSTALLMENTS) installmentCount!: number;
  /** Per period; omitted = even split rounded up. The last period takes what is left. */
  @ValidateIf(nullable) @IsString() @positiveMinor installmentMinor?: string | null;
  @IsString() @day firstDueOn!: string;
}

export class CloseCardInstallmentDto {
  @Type(() => Number) @IsInt() @Min(1) @Max(2147483646) version!: number;
}

export class ListCardInstallmentsDto {
  @ValidateIf(optional) @Transform(lower) @IsUUID() accountId?: string;
  @ValidateIf(optional) @IsIn(['active', 'closed']) status?: 'active' | 'closed';
}

export class CardInstallmentDueDto {
  @IsString() @day from!: string;
  @IsString() @day to!: string;
  @ValidateIf(optional) @Transform(lower) @IsUUID() accountId?: string;
}
