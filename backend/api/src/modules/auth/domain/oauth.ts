import type { Session } from './auth.repository';

export type OAuthProvider = 'google' | 'apple';
export interface OAuthIdentity {
  provider: OAuthProvider;
  subject: string;
  email?: string;
}
export const OAUTH_VERIFIER = Symbol('OAUTH_VERIFIER');
export interface OAuthVerifier {
  assertEnabled(provider: OAuthProvider): void;
  verify(
    provider: OAuthProvider,
    idToken: string,
    nonce: string,
  ): Promise<OAuthIdentity>;
}
export const OAUTH_REPOSITORY = Symbol('OAUTH_REPOSITORY');
export interface OAuthRepository {
  createChallenge(
    provider: OAuthProvider,
    tokenHash: string,
    expiresAt: Date,
  ): Promise<void>;
  hasChallenge(provider: OAuthProvider, tokenHash: string): Promise<boolean>;
  login(
    identity: OAuthIdentity,
    challengeHash: string,
    sessionHash: string,
    expiresAt: Date,
  ): Promise<Session | null>;
}
