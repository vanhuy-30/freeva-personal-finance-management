import { Transform, Type } from 'class-transformer';
import { IsBoolean, IsInt, IsOptional, IsString, Matches, Min } from 'class-validator';

const trim = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim() : value);

export class PutNotificationPreferencesDto {
  @IsOptional() @IsBoolean() budgetEnabled?: boolean;
  @IsOptional() @IsBoolean() goalEnabled?: boolean;
  @IsOptional() @IsBoolean() debtEnabled?: boolean;
  @IsOptional() @IsBoolean() cardEnabled?: boolean;
  @IsOptional() @IsBoolean() recurringEnabled?: boolean;
  @IsOptional() @IsBoolean() monthReviewEnabled?: boolean;
  @IsOptional() @IsBoolean() insightEnabled?: boolean;
  @IsOptional() @IsBoolean() quietHoursEnabled?: boolean;
  @IsOptional()
  @Transform(trim)
  @IsString()
  @Matches(/^([01]\d|2[0-3]):([0-5]\d)$/)
  quietStart?: string;
  @IsOptional()
  @Transform(trim)
  @IsString()
  @Matches(/^([01]\d|2[0-3]):([0-5]\d)$/)
  quietEnd?: string;
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) version?: number;
}

export class NotificationIdParamDto {
  @IsString()
  @Matches(/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i)
  id!: string;
}
