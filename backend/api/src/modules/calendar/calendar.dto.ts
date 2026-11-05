import { IsString, Matches } from 'class-validator';

export class CalendarQueryDto {
  @IsString()
  @Matches(/^\d{4}-\d{2}$/)
  month!: string;
}
