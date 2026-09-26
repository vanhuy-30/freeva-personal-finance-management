import { Transform, Type } from 'class-transformer';
import { IsBoolean, IsIn, IsInt, IsString, IsUUID, Length, Max, Min, ValidateIf } from 'class-validator';
import { CATEGORY_ICONS } from './domain/category';
const optional = (_: unknown, value: unknown) => value !== undefined;
const nullable = (_: unknown, value: unknown) => value !== undefined && value !== null;
const trim = ({ value }: { value: unknown }) => typeof value === 'string' ? value.trim() : value;
const lower = ({ value }: { value: unknown }) => typeof value === 'string' ? value.toLowerCase() : value;
export class CreateCategoryDto {
  @Transform(lower) @IsUUID() clientId!: string;
  @Transform(trim) @IsString() @Length(1, 100) name!: string;
  @ValidateIf(nullable) @Transform(lower) @IsUUID() parentId?: string | null;
  @ValidateIf(nullable) @IsString() @Length(1, 100) colorToken?: string | null;
  @ValidateIf(nullable) @IsIn(CATEGORY_ICONS) iconToken?: string | null;
}
export class UpdateCategoryDto {
  @IsInt() @Min(1) @Max(2147483646) version!: number;
  @ValidateIf(optional) @Transform(trim) @IsString() @Length(1, 100) name?: string;
  @ValidateIf(nullable) @Transform(lower) @IsUUID() parentId?: string | null;
  @ValidateIf(nullable) @IsString() @Length(1, 100) colorToken?: string | null;
  @ValidateIf(nullable) @IsIn(CATEGORY_ICONS) iconToken?: string | null;
  @ValidateIf(optional) @IsBoolean() archived?: boolean;
}
export class CategoryQueryDto {
  @Type(() => Number) @IsInt() @Min(1) @Max(2147483647) page = 1;
  @Type(() => Number) @IsInt() @Min(1) @Max(100) pageSize = 50;
  @IsIn(['active', 'archived', 'all']) status: 'active' | 'archived' | 'all' = 'active';
  @ValidateIf((_: unknown, value: unknown) => value !== undefined && value !== 'root') @Transform(lower) @IsUUID() parentId?: string;
}
export class CategoryIdDto {
  @Transform(lower) @IsUUID() id!: string;
}
export class DeleteCategoryDto {
  @Type(() => Number) @IsInt() @Min(1) @Max(2147483646) version!: number;
  @ValidateIf(optional) @Transform(lower) @IsUUID() replacementCategoryId?: string;
}
