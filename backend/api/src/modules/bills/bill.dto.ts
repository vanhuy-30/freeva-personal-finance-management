import { Transform, Type } from 'class-transformer';
import {
  IsIn, IsInt, IsOptional, IsString, IsUUID, Length, Matches, Max, Min, ValidateIf,
} from 'class-validator';
import { BILL_AMOUNT_KINDS, BILL_STATUSES } from './domain/bill';

const optional = (_: unknown, value: unknown) => value !== undefined;
const lower = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.toLowerCase() : value);
const upper = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.toUpperCase() : value);
const day = Matches(/^\d{4}-\d{2}-\d{2}$/);
const positiveMinor = Matches(/^[1-9][0-9]*$/);

export class CreateBillDto {
  @Transform(lower) @IsUUID() clientId!: string;
  @IsString() @Length(1, 80) name!: string;
  @IsString() @day dueOn!: string;
  @IsString() @Length(1, 20) @positiveMinor amountMinor!: string;
  @IsIn([...BILL_AMOUNT_KINDS]) amountKind!: typeof BILL_AMOUNT_KINDS[number];
  @Transform(upper) @IsString() @Length(3, 3) currencyCode!: string;
  @ValidateIf(optional) @Transform(({ value }) => value === null ? null : typeof value === 'string' ? value.toLowerCase() : value)
  @IsUUID() recurringRuleId?: string | null;
}

export class UpdateBillDto {
  @IsInt() @Min(1) @Max(2147483646) version!: number;
  @ValidateIf(optional) @IsString() @Length(1, 80) name?: string;
  @ValidateIf(optional) @IsString() @day dueOn?: string;
  @ValidateIf(optional) @IsString() @Length(1, 20) @positiveMinor amountMinor?: string;
  @ValidateIf(optional) @IsIn([...BILL_AMOUNT_KINDS]) amountKind?: typeof BILL_AMOUNT_KINDS[number];
  @ValidateIf(optional) @Transform(upper) @IsString() @Length(3, 3) currencyCode?: string;
  @ValidateIf(optional) @Transform(({ value }) => value === null ? null : typeof value === 'string' ? value.toLowerCase() : value)
  @IsUUID() recurringRuleId?: string | null;
}

export class PayBillDto {
  @IsInt() @Min(1) @Max(2147483646) version!: number;
  @Transform(lower) @IsUUID() transactionId!: string;
}

export class UnpayBillDto {
  @IsInt() @Min(1) @Max(2147483646) version!: number;
}

export class BillQueryDto {
  @Type(() => Number) @IsInt() @Min(1) @Max(2147483647) page = 1;
  @Type(() => Number) @IsInt() @Min(1) @Max(100) pageSize = 50;
  @IsOptional() @IsIn([...BILL_STATUSES]) status?: typeof BILL_STATUSES[number];
}

export class BillIdDto {
  @Transform(lower) @IsUUID() id!: string;
}

export class DeleteBillDto {
  @Type(() => Number) @IsInt() @Min(1) @Max(2147483646) version!: number;
}
