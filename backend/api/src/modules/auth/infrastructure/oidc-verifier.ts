import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { isEmail } from 'class-validator';
import { createRemoteJWKSet, errors, jwtVerify } from 'jose';
import type {
  OAuthIdentity,
  OAuthProvider,
  OAuthVerifier,
} from '../domain/oauth';
import { unauthorized } from '../auth.service';

const providers = {
  google: {
    issuer: ['https://accounts.google.com', 'accounts.google.com'],
    jwks: 'https://www.googleapis.com/oauth2/v3/certs',
    env: 'GOOGLE_OAUTH_CLIENT_IDS',
  },
  apple: {
    issuer: ['https://appleid.apple.com'],
    jwks: 'https://appleid.apple.com/auth/keys',
    env: 'APPLE_OAUTH_CLIENT_IDS',
  },
};

@Injectable()
export class OidcVerifier implements OAuthVerifier {
  private readonly audiences: Record<OAuthProvider, string[]>;
  private readonly keys = {
    google: createRemoteJWKSet(new URL(providers.google.jwks), {
      timeoutDuration: 5000,
    }),
    apple: createRemoteJWKSet(new URL(providers.apple.jwks), {
      timeoutDuration: 5000,
    }),
  };

  constructor(config: ConfigService) {
    const read = (provider: OAuthProvider) =>
      (config.get<string>(providers[provider].env) ?? '')
        .split(',')
        .map((value) => value.trim())
        .filter(Boolean);
    this.audiences = { google: read('google'), apple: read('apple') };
  }

  assertEnabled(provider: OAuthProvider): void {
    if (!this.audiences[provider]?.length)
      throw new ServiceUnavailableException({
        error: {
          code: 'OAUTH_UNAVAILABLE',
          message: 'Identity provider is unavailable',
        },
      });
  }

  async verify(
    provider: OAuthProvider,
    idToken: string,
    nonce: string,
  ): Promise<OAuthIdentity> {
    this.assertEnabled(provider);
    let payload;
    try {
      ({ payload } = await jwtVerify(idToken, this.keys[provider], {
        algorithms: ['RS256'],
        issuer: providers[provider].issuer,
        audience: this.audiences[provider],
        requiredClaims: ['sub', 'iat', 'exp', 'nonce'],
        maxTokenAge: '10m',
      }));
    } catch (error) {
      // Never expose provider errors or JWT contents. Network/key service failures are retryable.
      if (
        error instanceof errors.JWTInvalid ||
        error instanceof errors.JWTClaimValidationFailed ||
        error instanceof errors.JWTExpired ||
        error instanceof errors.JWSInvalid ||
        error instanceof errors.JWSSignatureVerificationFailed ||
        error instanceof errors.JOSEAlgNotAllowed ||
        error instanceof errors.JOSENotSupported ||
        error instanceof errors.JWKSNoMatchingKey
      )
        throw unauthorized();
      throw new ServiceUnavailableException({
        error: {
          code: 'OAUTH_UNAVAILABLE',
          message: 'Identity provider is unavailable',
        },
      });
    }
    if (
      payload.nonce !== nonce ||
      typeof payload.sub !== 'string' ||
      !payload.sub ||
      payload.sub.length > 255 ||
      (payload.azp !== undefined &&
        (typeof payload.azp !== 'string' ||
          !this.audiences[provider].includes(payload.azp))) ||
      (Array.isArray(payload.aud) && payload.aud.length > 1 && !payload.azp)
    )
      throw unauthorized();
    const verified =
      payload.email_verified === true ||
      (provider === 'apple' && payload.email_verified === 'true');
    const email =
      typeof payload.email === 'string'
        ? payload.email.trim().toLowerCase()
        : undefined;
    return {
      provider,
      subject: payload.sub,
      ...(verified && email && email.length <= 254 && isEmail(email)
        ? { email }
        : {}),
    };
  }
}
