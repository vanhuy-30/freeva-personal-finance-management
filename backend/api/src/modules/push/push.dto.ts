import { Transform } from 'class-transformer';
import { IsIn, IsString, MaxLength, MinLength } from 'class-validator';

const trim = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim() : value);

export class PutPushTokenDto {
  @Transform(trim) @IsString() @MinLength(20) @MaxLength(4096) token!: string;
  @IsIn(['ios', 'android']) platform!: 'ios' | 'android';
}
