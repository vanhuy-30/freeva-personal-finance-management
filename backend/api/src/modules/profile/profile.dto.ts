import {
  IsIn, IsInt, IsString, Matches, Max, MaxLength, Min,
} from 'class-validator';

export class UpdateProfileDto {
  @IsIn(['vi', 'en'])
  locale!: string;

  @IsString()
  @Matches(/^[A-Z]{3}$/)
  defaultCurrencyCode!: string;

  @IsString()
  @MaxLength(100)
  timezone!: string;

  @IsInt()
  @Min(1)
  @Max(28)
  fiscalMonthStartDay!: number;

  @IsInt()
  @Min(1)
  @Max(2147483646)
  version!: number;
}
