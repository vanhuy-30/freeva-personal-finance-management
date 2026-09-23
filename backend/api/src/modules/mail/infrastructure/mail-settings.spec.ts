import { ConfigService } from '@nestjs/config';
import { readMailSettings } from './mail-settings';

export function isolatedConfig(values: Record<string, unknown>): ConfigService {
  const config = new ConfigService(values);
  jest.spyOn(config, 'get').mockImplementation((key: string) => values[key]);
  return config;
}

const smtp = { SMTP_HOST: 'smtp.example.test', SMTP_FROM: 'Freeva <noreply@example.test>' };
const resend = { MAIL_PROVIDER: 'resend', MAIL_FROM: 'Freeva <onboarding@resend.dev>', RESEND_API_KEY: 'test-key' };

describe('mail configuration', () => {
  it('uses a Resend preset without accepting a host/user override for the API key', () => {
    expect(readMailSettings(isolatedConfig({ ...resend, SMTP_HOST: 'other.example.test', SMTP_USER: 'other' })))
      .toEqual({ from: resend.MAIL_FROM, host: 'smtp.resend.com', port: 2465,
        secure: true, requireTLS: true, auth: { user: 'resend', pass: 'test-key' },
        idempotencyHeader: 'Resend-Idempotency-Key' });
  });

  it.each(['staging', 'production', undefined])('requires TLS outside explicit local/test: %s', (NODE_ENV) => {
    expect(readMailSettings(isolatedConfig({ ...smtp, NODE_ENV })))
      .toMatchObject({ requireTLS: true, secure: false });
  });

  it.each(['465', '2465'])('uses implicit TLS for Resend port %s', (SMTP_PORT) => {
    expect(readMailSettings(isolatedConfig({ ...resend, SMTP_PORT }))).toMatchObject({ secure: true, requireTLS: true });
  });

  it.each(['587', '2587', '25'])('requires STARTTLS for Resend port %s even in development', (SMTP_PORT) => {
    expect(readMailSettings(isolatedConfig({ ...resend, SMTP_PORT, NODE_ENV: 'development' })))
      .toMatchObject({ secure: false, requireTLS: true });
  });

  it('supports old SMTP envs and switching vendors without auth changes', () => {
    const settings = readMailSettings(isolatedConfig({ ...smtp, SMTP_PORT: '1025', NODE_ENV: 'test' }));
    expect(settings).toMatchObject({ host: smtp.SMTP_HOST, from: smtp.SMTP_FROM, requireTLS: false });
    expect(settings.idempotencyHeader).toBeUndefined();
    expect(readMailSettings(isolatedConfig({ ...smtp, SMTP_PORT: '2525', SMTP_SECURE: 'true',
      SMTP_USER: 'other-provider', SMTP_PASSWORD: 'other-secret' })))
      .toMatchObject({ secure: true, auth: { user: 'other-provider', pass: 'other-secret' } });
  });

  it.each([
    {}, { ...smtp, MAIL_PROVIDER: 'unknown' }, { ...smtp, SMTP_PORT: 'invalid' },
    { ...smtp, SMTP_PORT: '0' }, { ...smtp, SMTP_USER: 'user' },
    { ...smtp, SMTP_SECURE: 'yes' }, { ...resend, RESEND_API_KEY: '' },
    { ...resend, SMTP_PORT: '1025' }, { ...resend, SMTP_PORT: '2465', SMTP_SECURE: 'false' },
    { ...resend, MAIL_FROM: 'invalid' }, { ...resend, MAIL_FROM: 'a@example.test\r\nBcc:b@example.test' },
  ])('rejects invalid configuration without printing values (%#)', (values) => {
    expect(() => readMailSettings(isolatedConfig(values))).toThrow();
  });
});
