import { appConfigReaderFor } from '../app-config/testing';
import { AuthService } from './auth.service';
import type { AuthRepository } from './domain/auth.repository';
import type { AuthCrypto } from './infrastructure/auth-crypto';

describe('MOB-P1-001 email-first entry', () => {
  const findUser = jest.fn();
  const service = new AuthService(
    { findUser } as unknown as AuthRepository,
    {} as AuthCrypto,
    appConfigReaderFor(),
  );
  beforeEach(() => findUser.mockReset());

  it('routes a new email to registration without creating an account', async () => {
    findUser.mockResolvedValue(null);
    await expect(service.emailStep('new@example.test')).resolves.toEqual({
      nextStep: 'register',
    });
    expect(findUser).toHaveBeenCalledWith('new@example.test');
  });

  it.each(['hash', null])(
    'routes existing and legacy accounts to login without exposing details',
    async (passwordHash) => {
      findUser.mockResolvedValue({
        id: 'private-id',
        email: 'private@example.test',
        passwordHash,
      });
      await expect(service.emailStep('private@example.test')).resolves.toEqual({
        nextStep: 'login',
      });
    },
  );

  it('propagates storage failure instead of guessing registration', async () => {
    findUser.mockRejectedValue(new Error('unavailable'));
    await expect(service.emailStep('user@example.test')).rejects.toThrow(
      'unavailable',
    );
  });
});

describe('SEC-P6-002 confirm identity before account delete/export', () => {
  const findUserById = jest.fn();
  const takeRateLimit = jest.fn();
  const verifyPassword = jest.fn();
  const service = new AuthService(
    { findUserById, takeRateLimit } as unknown as AuthRepository,
    { verifyPassword, rateKey: (key: string) => `k:${key}` } as unknown as AuthCrypto,
    appConfigReaderFor(),
  );
  const now = new Date('2026-11-12T10:00:00.000Z');
  const session = (minutesAgo: number) => ({
    userId: 'u1',
    createdAt: new Date(now.getTime() - minutesAgo * 60_000),
  });
  const error = (promise: Promise<unknown>) =>
    promise.then(
      () => null,
      (e: { getStatus(): number; getResponse(): { error: { code: string } } }) => ({
        status: e.getStatus(),
        code: e.getResponse().error.code,
      }),
    );

  beforeEach(() => {
    jest.resetAllMocks();
    takeRateLimit.mockResolvedValue(0);
  });

  it('accepts the right password on an old session', async () => {
    findUserById.mockResolvedValue({ id: 'u1', passwordHash: 'hash' });
    verifyPassword.mockResolvedValue(true);
    await expect(service.confirmIdentity(session(600), 'secret', now)).resolves.toBeUndefined();
    expect(verifyPassword).toHaveBeenCalledWith('hash', 'secret');
    expect(takeRateLimit).toHaveBeenCalledWith('k:user:reauth:u1', 5, 900);
  });

  it.each([undefined, 'wrong'])('refuses a missing or wrong password (%j), even on a fresh session', async (password) => {
    findUserById.mockResolvedValue({ id: 'u1', passwordHash: 'hash' });
    verifyPassword.mockResolvedValue(false);
    expect(await error(service.confirmIdentity(session(0), password, now))).toEqual({
      status: 403,
      code: 'INVALID_CREDENTIALS',
    });
  });

  it('is rate limited per user before checking the password', async () => {
    findUserById.mockResolvedValue({ id: 'u1', passwordHash: 'hash' });
    takeRateLimit.mockResolvedValue(60);
    expect(await error(service.confirmIdentity(session(0), 'secret', now))).toEqual({
      status: 429,
      code: 'RATE_LIMITED',
    });
    expect(verifyPassword).not.toHaveBeenCalled();
  });

  it('lets an OAuth-only account through only within 10 minutes of sign-in', async () => {
    findUserById.mockResolvedValue({ id: 'u1', passwordHash: null });
    await expect(service.confirmIdentity(session(10), undefined, now)).resolves.toBeUndefined();
    expect(await error(service.confirmIdentity(session(11), undefined, now))).toEqual({
      status: 403,
      code: 'REAUTH_REQUIRED',
    });
  });

  it('treats a vanished user as an invalid session', async () => {
    findUserById.mockResolvedValue(null);
    expect(await error(service.confirmIdentity(session(0), 'secret', now))).toEqual({
      status: 401,
      code: 'INVALID_CREDENTIALS',
    });
  });
});
