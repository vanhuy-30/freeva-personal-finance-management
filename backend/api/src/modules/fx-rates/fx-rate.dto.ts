import { IsISO8601, IsOptional, IsString, Matches } from 'class-validator';

export class FxRatePairParams {
  @IsString() @Matches(/^[A-Z]{3}$/) from!: string;
  @IsString() @Matches(/^[A-Z]{3}$/) to!: string;
}

/** User-typed rate for display conversion. `quotedAt` omitted means now. */
export class PutFxRateDto {
  @IsString() @Matches(/^\d{1,10}(\.\d{1,8})?(?![\s\S])/) rate!: string;
  @IsOptional() @IsISO8601({ strict: true }) quotedAt?: string;
}
