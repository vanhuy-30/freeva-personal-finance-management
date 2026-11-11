import { Transform } from 'class-transformer';
import { IsArray, IsBoolean, IsDefined, IsInt, Max, Min } from 'class-validator';

/** Shape checks only; per-key rules live in the domain (`parseFlagState`, `parseConfigValue`). */
export class UpdateFlagDto {
  @IsBoolean() enabled!: boolean;
  @IsArray() userIds!: string[];
  @IsInt() @Min(0) @Max(100) percentage!: number;
  @IsInt() @Min(0) version!: number;
}

export class UpdateConfigValueDto {
  @IsDefined() value!: unknown;
  @IsInt() @Min(0) version!: number;
}

export class ResetConfigValueQueryDto {
  @Transform(({ value }) => (typeof value === 'string' && /^\d+$/.test(value) ? Number(value) : value))
  @IsInt() @Min(1) version!: number;
}
