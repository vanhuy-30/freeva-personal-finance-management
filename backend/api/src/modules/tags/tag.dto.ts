import { Transform, Type } from 'class-transformer';
import { IsInt, IsString, IsUUID, Length, Max, Min, ValidateIf } from 'class-validator';
const optional = (_: unknown, value: unknown) => value !== undefined;
const trim = ({ value }: { value: unknown }) => typeof value === 'string' ? value.trim() : value;
const lower = ({ value }: { value: unknown }) => typeof value === 'string' ? value.toLowerCase() : value;
export class CreateTagDto {
  @Transform(lower) @IsUUID() clientId!: string;
  @Transform(trim) @IsString() @Length(1, 100) name!: string;
}
export class UpdateTagDto {
  @IsInt() @Min(1) @Max(2147483646) version!: number;
  @ValidateIf(optional) @Transform(trim) @IsString() @Length(1, 100) name?: string;
}
export class TagQueryDto {
  @Type(() => Number) @IsInt() @Min(1) @Max(2147483647) page = 1;
  @Type(() => Number) @IsInt() @Min(1) @Max(100) pageSize = 50;
}
export class TagIdDto {
  @Transform(lower) @IsUUID() id!: string;
}
export class DeleteTagDto {
  @Type(() => Number) @IsInt() @Min(1) @Max(2147483646) version!: number;
}
