import { AuthService } from './auth.service';
import type { AuthRepository } from './domain/auth.repository';
import type { AuthCrypto } from './infrastructure/auth-crypto';

describe('MOB-P1-001 email-first entry', () => {
  const findUser = jest.fn();
  const service = new AuthService(
    { findUser } as unknown as AuthRepository,
    {} as AuthCrypto,
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
