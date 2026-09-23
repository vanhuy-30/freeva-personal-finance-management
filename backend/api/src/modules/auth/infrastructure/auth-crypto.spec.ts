import { ConfigService } from '@nestjs/config';
import { AuthCrypto } from './auth-crypto';

describe('AuthCrypto', () => {
  const crypto = new AuthCrypto(
    new ConfigService({ AUTH_SECRET_KEY: 'a'.repeat(64) }),
  );
  beforeAll(async () => crypto.onModuleInit());
  it('uses salted Argon2id and rejects incorrect/missing hashes', async () => {
    const password = 'a sufficiently long password';
    const hash = await crypto.hashPassword(password);
    expect(hash).toMatch(/^\$argon2id\$v=19\$/);
    expect(hash.split('$')[3].split(',').sort()).toEqual([
      'm=19456',
      'p=1',
      't=2',
    ]);
    expect(hash).not.toBe(await crypto.hashPassword(password));
    expect(await crypto.verifyPassword(hash, password)).toBe(true);
    expect(await crypto.verifyPassword(hash, 'incorrect')).toBe(false);
    expect(await crypto.verifyPassword(null, password)).toBe(false);
  });
  it('generates distinct 256-bit tokens, encrypts with random nonces and authenticates ciphertext', () => {
    const token = crypto.token();
    expect(token).toMatch(/^[a-f0-9]{64}$/);
    expect(token).not.toBe(crypto.token());
    const encrypted = crypto.encrypt(token);
    expect(encrypted).not.toContain(token);
    expect(crypto.decrypt(encrypted)).toBe(token);
    expect(crypto.encrypt(token)).not.toBe(encrypted);
    const corrupted = Buffer.from(encrypted, 'base64');
    corrupted[30] ^= 1;
    expect(() => crypto.decrypt(corrupted.toString('base64'))).toThrow();
  });
  it('requires secret configuration and keys counters with a secret', () => {
    expect(() => new AuthCrypto(new ConfigService())).toThrow(
      'AUTH_SECRET_KEY',
    );
    const other = new AuthCrypto(
      new ConfigService({ AUTH_SECRET_KEY: 'b'.repeat(64) }),
    );
    expect(crypto.rateKey('email:user@example.test')).not.toBe(
      other.rateKey('email:user@example.test'),
    );
  });
});
