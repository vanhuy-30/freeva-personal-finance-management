import { Transform, Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Length,
  Matches,
  Max,
  Min,
  ValidateIf,
  ValidateNested,
} from 'class-validator';
import { BUDGET_APPLY_TO } from './domain/budget';

const optional = (_: unknown, value: unknown) => value !== undefined;
const lower = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.toLowerCase() : value);
const day = Matches(/^\d{4}-\d{2}-\d{2}$/);
const positiveMinor = Matches(/^[1-9][0-9]*$/);

export class BudgetCategoryLineDto {
  @Transform(lower) @IsUUID() categoryId!: string;
  @IsString() @Length(1, 20) @positiveMinor limitMinor!: string;
}

export class PutBudgetDto {
  @IsString() @Length(1, 20) @positiveMinor limitMinor!: string;
  @ValidateIf(optional)
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(4)
  @IsInt({ each: true })
  @Min(1, { each: true })
  @Max(100, { each: true })
  alertThresholds?: number[];

  @ValidateIf(optional)
  @IsArray()
  @ArrayMaxSize(100)
  @ValidateNested({ each: true })
  @Type(() => BudgetCategoryLineDto)
  categories?: BudgetCategoryLineDto[];

  @ValidateIf(optional) @Type(() => Number) @IsInt() @Min(1) @Max(2147483646) version?: number;

  /** default = template for every month; month = override for the fiscal month of `on`. */
  @ValidateIf(optional) @IsIn([...BUDGET_APPLY_TO]) applyTo?: (typeof BUDGET_APPLY_TO)[number];

  /** Required when applyTo is month (calendar day in the profile timezone). */
  @ValidateIf((o: PutBudgetDto) => (o.applyTo ?? 'default') === 'month')
  @IsString()
  @day
  on?: string;
}

export class BudgetQueryDto {
  @ValidateIf(optional) @IsString() @day on?: string;
  /** When `default`, return the template only (ignore month overrides). */
  @ValidateIf(optional) @IsIn([...BUDGET_APPLY_TO]) applyTo?: (typeof BUDGET_APPLY_TO)[number];
}

export class DeleteBudgetDto {
  @ValidateIf(optional) @Type(() => Number) @IsInt() @Min(1) @Max(2147483646) version?: number;
  @ValidateIf(optional) @IsIn([...BUDGET_APPLY_TO]) applyTo?: (typeof BUDGET_APPLY_TO)[number];
  @ValidateIf((o: DeleteBudgetDto) => (o.applyTo ?? 'default') === 'month')
  @IsString()
  @day
  on?: string;
}
