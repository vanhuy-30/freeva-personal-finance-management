import { IsIn, IsString, Matches, MaxLength, MinLength } from 'class-validator';
import type { OAuthProvider } from '../domain/oauth';

export class OAuthChallengeDto {
  @IsIn(['google', 'apple'])
  provider!: OAuthProvider;
}

export class OAuthLoginDto extends OAuthChallengeDto {
  @IsString()
  @Matches(/^[a-f0-9]{64}$/)
  challengeToken!: string;

  @IsString()
  @MinLength(1)
  @MaxLength(16384)
  idToken!: string;
}
