import { Transform, Type } from 'class-transformer';
import {
  IsBoolean,
  IsIn,
  IsInt,
  IsString,
  IsUUID,
  Length,
  Matches,
  Max,
  Min,
  ValidateIf,
} from 'class-validator';
import { GOAL_KINDS } from './domain/goal';

const optional = (_: unknown, value: unknown) => value !== undefined;
const nullable = (_: unknown, value: unknown) => value !== undefined && value !== null;
const lower = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.toLowerCase() : value);
const trim = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim() : value);
const day = Matches(/^\d{4}-\d{2}-\d{2}(?![\s\S])/);
const positiveMinor = Matches(/^[1-9][0-9]{0,18}(?![\s\S])/);
const nonNegativeMinor = Matches(/^(0|[1-9][0-9]{0,18})(?![\s\S])/);
const version = [Type(() => Number), IsInt(), Min(1), Max(2147483646)];
const applyAll = (decorators: PropertyDecorator[]) => (target: object, key: string) => {
  for (const decorator of decorators) decorator(target, key);
};

export class CreateGoalDto {
  @Transform(lower) @IsUUID() clientId!: string;
  @IsIn([...GOAL_KINDS]) kind!: (typeof GOAL_KINDS)[number];
  @Transform(trim) @IsString() @Length(1, 80) name!: string;
  @IsString() @positiveMinor targetMinor!: string;
  @ValidateIf(optional) @IsString() @nonNegativeMinor currentMinor?: string;
  @ValidateIf(nullable) @IsString() @day targetDate?: string | null;
  @Transform(lower) @IsUUID() accountId!: string;
  @ValidateIf(nullable) @IsString() @nonNegativeMinor monthlyContributionMinor?: string | null;
  @ValidateIf(optional) @IsString() @Length(1, 30) icon?: string;
  @ValidateIf(nullable) @IsString() @Length(1, 40) colorToken?: string | null;
}

export class UpdateGoalDto {
  @applyAll(version) version!: number;
  @ValidateIf(optional) @IsIn([...GOAL_KINDS]) kind?: (typeof GOAL_KINDS)[number];
  @ValidateIf(optional) @Transform(trim) @IsString() @Length(1, 80) name?: string;
  @ValidateIf(optional) @IsString() @positiveMinor targetMinor?: string;
  @ValidateIf(nullable) @IsString() @day targetDate?: string | null;
  @ValidateIf(nullable) @IsString() @nonNegativeMinor monthlyContributionMinor?: string | null;
  @ValidateIf(optional) @IsString() @Length(1, 30) icon?: string;
  @ValidateIf(nullable) @IsString() @Length(1, 40) colorToken?: string | null;
}

export class ArchiveGoalDto {
  @applyAll(version) version!: number;
}

export class ListGoalsDto {
  @ValidateIf(optional)
  @Transform(({ value }) => value === 'true' || value === true)
  @IsBoolean()
  includeArchived?: boolean;
}

export class MoveGoalDto {
  @Transform(lower) @IsUUID() clientId!: string;
  @IsString() @positiveMinor amountMinor!: string;
  /** Wallet the money comes from (contribute) or goes to (withdraw); omit when it already sits in the linked wallet. */
  @ValidateIf(nullable) @Transform(lower) @IsUUID() accountId?: string | null;
  @IsString() @day occurredOn!: string;
}

export class AdjustGoalDto {
  @IsString() @nonNegativeMinor currentMinor!: string;
  @applyAll(version) version!: number;
}
