import { Inject, Injectable } from '@nestjs/common';
import {
  OAUTH_REPOSITORY,
  OAUTH_VERIFIER,
  type OAuthProvider,
  type OAuthRepository,
  type OAuthVerifier,
} from './domain/oauth';
import { AuthCrypto } from './infrastructure/auth-crypto';
import { unauthorized } from './auth.service';

@Injectable()
export class OAuthService {
  constructor(
    @Inject(OAUTH_REPOSITORY) private readonly repository: OAuthRepository,
    @Inject(OAUTH_VERIFIER) private readonly verifier: OAuthVerifier,
    private readonly crypto: AuthCrypto,
  ) {}

  async challenge(provider: OAuthProvider) {
    this.verifier.assertEnabled(provider);
    const challengeToken = this.crypto.token();
    const nonce = this.crypto.digest(challengeToken);
    const expiresAt = new Date(Date.now() + 5 * 60_000);
    await this.repository.createChallenge(provider, nonce, expiresAt);
    return { challengeToken, nonce, expiresAt };
  }

  async login(
    provider: OAuthProvider,
    idToken: string,
    challengeToken: string,
  ) {
    this.verifier.assertEnabled(provider);
    const nonce = this.crypto.digest(challengeToken);
    if (!(await this.repository.hasChallenge(provider, nonce)))
      throw unauthorized();
    const identity = await this.verifier.verify(provider, idToken, nonce);
    const accessToken = this.crypto.token();
    const session = await this.repository.login(
      identity,
      nonce,
      this.crypto.digest(accessToken),
      new Date(Date.now() + 7 * 24 * 60 * 60_000),
    );
    if (!session) throw unauthorized();
    return {
      accessToken,
      tokenType: 'Bearer' as const,
      expiresAt: session.expiresAt,
      sessionId: session.id,
    };
  }
}
