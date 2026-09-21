import { ConfigService } from '@nestjs/config';
import { createTransport } from 'nodemailer';
import { AuthMailWorker } from './auth-mail.worker';
import { AuthCrypto } from './auth-crypto';
import type { AuthRepository } from '../domain/auth.repository';

jest.mock('nodemailer', () => ({
  createTransport: jest.fn(() => ({ close: jest.fn() })),
}));

function isolatedConfig(values: Record<string, unknown> = {}): ConfigService {
  const config = new ConfigService(values);
  jest.spyOn(config, 'get').mockImplementation((key: string) => values[key]);
  return config;
}

describe('SMTP configuration', () => {
  const repository = {} as AuthRepository;
  const crypto = {} as AuthCrypto;
  const config = {
    SMTP_HOST: 'smtp.example.test',
    SMTP_FROM: 'noreply@example.test',
  };

  it.each(['staging', 'production', undefined])(
    'requires TLS outside explicit local/test: %s',
    (NODE_ENV) => {
      new AuthMailWorker(
        repository,
        crypto,
        isolatedConfig({ ...config, NODE_ENV }),
      );
      expect(createTransport).toHaveBeenLastCalledWith(
        expect.objectContaining({
          requireTLS: true,
          secure: false,
          debug: false,
          logger: false,
        }),
      );
    },
  );

  it('uses implicit TLS on port 465 and permits local Mailhog without TLS', () => {
    new AuthMailWorker(
      repository,
      crypto,
      isolatedConfig({ ...config, SMTP_PORT: '465' }),
    );
    expect(createTransport).toHaveBeenLastCalledWith(
      expect.objectContaining({ secure: true, requireTLS: true }),
    );
    new AuthMailWorker(
      repository,
      crypto,
      isolatedConfig({
        ...config,
        NODE_ENV: 'development',
        SMTP_PORT: '1025',
      }),
    );
    expect(createTransport).toHaveBeenLastCalledWith(
      expect.objectContaining({ secure: false, requireTLS: false }),
    );
  });

  it('rejects missing SMTP configuration, invalid ports and incomplete credentials', () => {
    for (const values of [
      {},
      { ...config, SMTP_PORT: 'invalid' },
      { ...config, SMTP_USER: 'user' },
    ]) {
      expect(
        () => new AuthMailWorker(repository, crypto, isolatedConfig(values)),
      ).toThrow();
    }
  });
});
