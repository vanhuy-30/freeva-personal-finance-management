import { ConfigService } from '@nestjs/config';
import { errors, createLocalJWKSet, exportJWK, generateKeyPair, SignJWT } from 'jose';
import { OidcVerifier } from './oidc-verifier';

const mockKeys = jest.fn();
jest.mock('jose', () => ({
  ...jest.requireActual('jose'),
  createRemoteJWKSet: () => mockKeys,
}));

describe('BE-P1-003 OIDC verification with signed JWTs', () => {
  let verifier: OidcVerifier;
  let privateKey: Awaited<ReturnType<typeof generateKeyPair>>['privateKey'];
  beforeAll(async () => {
    const keys = await generateKeyPair('RS256');
    privateKey = keys.privateKey;
    const jwk = await exportJWK(keys.publicKey);
    const resolve = createLocalJWKSet({
      keys: [{ ...jwk, kid: 'fixture', alg: 'RS256' }],
    });
    mockKeys.mockImplementation(resolve);
    verifier = new OidcVerifier(
      new ConfigService({
        GOOGLE_OAUTH_CLIENT_IDS: 'google-client',
        APPLE_OAUTH_CLIENT_IDS: 'apple-client',
      }),
    );
  });
  async function token(
    provider = 'google',
    claims: Record<string, unknown> = {},
    key = privateKey,
  ) {
    return new SignJWT({
      sub: 'stable-subject',
      iss:
        provider === 'google'
          ? 'https://accounts.google.com'
          : 'https://appleid.apple.com',
      aud: `${provider}-client`,
      iat: Math.floor(Date.now() / 1000),
      exp: Math.floor(Date.now() / 1000) + 300,
      nonce: 'server-nonce',
      email: ' Person@Example.test ',
      email_verified: provider === 'google' ? true : 'true',
      ...claims,
    })
      .setProtectedHeader({ alg: 'RS256', kid: 'fixture' })
      .sign(key);
  }
  it.each(['google', 'apple'] as const)(
    'verifies %s and normalizes only verified email',
    async (provider) => {
      expect(
        await verifier.verify(provider, await token(provider), 'server-nonce'),
      ).toEqual({
        provider,
        subject: 'stable-subject',
        email: 'person@example.test',
      });
      expect(
        await verifier.verify(
          provider,
          await token(provider, { email_verified: false }),
          'server-nonce',
        ),
      ).not.toHaveProperty('email');
      expect(
        await verifier.verify(
          provider,
          await token(provider, { email: undefined }),
          'server-nonce',
        ),
      ).not.toHaveProperty('email');
    },
  );
  it.each([
    { iss: 'https://attacker.test' },
    { aud: 'wrong-client' },
    { nonce: 'wrong' },
    { exp: 1 },
    { exp: undefined },
    { iat: undefined },
    { iat: 1 },
    { iat: Math.floor(Date.now() / 1000) + 3600 },
    { sub: '' },
    { sub: 123 },
    { sub: undefined },
    { azp: 'wrong-client' },
    { aud: ['google-client', 'other'] },
  ])('rejects invalid claims %p', async (claims) => {
    await expect(
      verifier.verify('google', await token('google', claims), 'server-nonce'),
    ).rejects.toMatchObject({ status: 401 });
  });
  it('rejects bad signatures, malformed JWT and cross-provider tokens', async () => {
    const other = await generateKeyPair('RS256');
    for (const jwt of [
      await token('google', {}, other.privateKey),
      'not-a-jwt',
      await token('apple'),
    ]) {
      await expect(
        verifier.verify('google', jwt, 'server-nonce'),
      ).rejects.toMatchObject({ status: 401 });
    }
  });
  it('fails closed without provider configuration', () => {
    expect(() =>
      new OidcVerifier(new ConfigService()).assertEnabled('google'),
    ).toThrow();
  });
  it('maps provider outage to a generic retryable error', async () => {
    mockKeys.mockRejectedValueOnce(new errors.JOSEError('sensitive provider error'));
    await expect(
      verifier.verify('google', await token(), 'server-nonce'),
    ).rejects.toMatchObject({
      status: 503,
      response: { error: { code: 'OAUTH_UNAVAILABLE' } },
    });
  });
});
