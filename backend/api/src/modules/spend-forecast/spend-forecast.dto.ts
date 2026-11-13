import { Transform } from 'class-transformer';
import { IsUUID } from 'class-validator';

const lower = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.toLowerCase() : value);

export class GoalForecastParamsDto {
  @Transform(lower) @IsUUID() id!: string;
}
