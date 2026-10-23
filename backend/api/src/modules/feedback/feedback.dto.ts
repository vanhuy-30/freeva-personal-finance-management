import { Transform } from 'class-transformer';
import { IsBoolean, IsIn, IsString, Length, Matches } from 'class-validator';
import { FEEDBACK_KINDS, FEEDBACK_TOPICS } from './domain/feedback';

const trim = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim() : value);

export class CreateFeedbackDto {
  @IsIn(FEEDBACK_KINDS) kind!: (typeof FEEDBACK_KINDS)[number];
  @IsIn(FEEDBACK_TOPICS) topic!: (typeof FEEDBACK_TOPICS)[number];
  @Transform(trim) @IsString() @Length(1, 2000) message!: string;
  @IsBoolean() allowReply!: boolean;
  @IsString() @Matches(/^[0-9A-Za-z.+_-]{1,30}$/) appVersion!: string;
}
