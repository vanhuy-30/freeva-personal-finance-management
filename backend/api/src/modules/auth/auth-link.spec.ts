import { ConfigService } from '@nestjs/config';
import {
  AUTH_LINK_PATHS,
  TOKEN_TTL_MINUTES,
  buildAuthEmail,
  buildAuthLink,
  readAppLinkSettings,
} from './auth-link';

function config(values: Record<string, unknown>): ConfigService {
  const service = new ConfigService(values);
  jest.spyOn(service, 'get').mockImplementation((key: string) => values[key]);
  return service;
}

const token = 'a'.repeat(64);

describe('readAppLinkSettings', () => {
  it.each([
    ['https://freeva-api-staging.onrender.com', 'https://freeva-api-staging.onrender.com'],
    ['https://freeva.com/', 'https://freeva.com'],
    ['  https://freeva.com//  ', 'https://freeva.com'],
    ['https://freeva.com/app/', 'https://freeva.com/app'],
    ['HTTPS://Freeva.COM', 'https://freeva.com'],
    ['https://freeva.com:8443', 'https://freeva.com:8443'],
  ])('normalises %s', (raw, expected) => {
    expect(readAppLinkSettings(config({ NODE_ENV: 'production', APP_LINK_BASE_URL: raw })))
      .toEqual({ baseUrl: expected });
  });

  it.each(['development', 'test'])('defaults to localhost in %s when unset', (NODE_ENV) => {
    expect(readAppLinkSettings(config({ NODE_ENV }))).toEqual({ baseUrl: 'http://localhost:3000' });
    expect(readAppLinkSettings(config({ NODE_ENV, APP_LINK_BASE_URL: '   ' })))
      .toEqual({ baseUrl: 'http://localhost:3000' });
  });

  it.each(['staging', 'production', undefined])('is required outside development/test: %s', (NODE_ENV) => {
    expect(() => readAppLinkSettings(config({ NODE_ENV }))).toThrow('APP_LINK_BASE_URL is required');
  });

  it('allows plain http only for loopback hosts in development/test', () => {
    expect(readAppLinkSettings(config({ NODE_ENV: 'development', APP_LINK_BASE_URL: 'http://127.0.0.1:3000/' })))
      .toEqual({ baseUrl: 'http://127.0.0.1:3000' });
    expect(() => readAppLinkSettings(config({ NODE_ENV: 'development', APP_LINK_BASE_URL: 'http://freeva.com' })))
      .toThrow('must use https');
    expect(() => readAppLinkSettings(config({ NODE_ENV: 'production', APP_LINK_BASE_URL: 'http://localhost:3000' })))
      .toThrow('must use https');
  });

  it.each([
    ['not a url', 'absolute URL'],
    ['freeva.com', 'absolute URL'],
    ['ftp://freeva.com', 'must use https'],
    ['javascript:alert(1)', 'must use https'],
    ['https://user:pw@freeva.com', 'credentials'],
    ['https://freeva.com?x=1', 'query or fragment'],
    ['https://freeva.com/#frag', 'query or fragment'],
  ])('rejects %s', (APP_LINK_BASE_URL, message) => {
    expect(() => readAppLinkSettings(config({ NODE_ENV: 'production', APP_LINK_BASE_URL }))).toThrow(message);
  });
});

describe('buildAuthLink', () => {
  const settings = { baseUrl: 'https://freeva.com' };

  it('puts the token in the fragment on the purpose path', () => {
    expect(buildAuthLink(settings, 'verify_email', token)).toBe(`https://freeva.com/verify-email#token=${token}`);
    expect(buildAuthLink(settings, 'reset_password', token)).toBe(`https://freeva.com/reset-password#token=${token}`);
  });

  it('never puts the token in the query string or path', () => {
    const url = new URL(buildAuthLink(settings, 'reset_password', token));
    expect(url.search).toBe('');
    expect(url.pathname).not.toContain(token);
    expect(url.hash).toBe(`#token=${token}`);
  });

  it('keeps a base path prefix and encodes unexpected characters', () => {
    expect(buildAuthLink({ baseUrl: 'https://freeva.com/app' }, 'verify_email', 'a b&c'))
      .toBe('https://freeva.com/app/verify-email#token=a%20b%26c');
  });

  it('uses the shared public paths', () => {
    expect(Object.values(AUTH_LINK_PATHS).sort()).toEqual(['reset-password', 'verify-email']);
  });
});

describe('buildAuthEmail', () => {
  const settings = { baseUrl: 'https://freeva.com' };

  it('states the lifetime from the shared constants', () => {
    expect(TOKEN_TTL_MINUTES).toEqual({ verify_email: 1440, reset_password: 30 });
    expect(buildAuthEmail(settings, 'verify_email', token).text).toContain('24 giờ');
    expect(buildAuthEmail(settings, 'reset_password', token).text).toContain('30 phút');
  });

  it.each(['verify_email', 'reset_password'] as const)('%s email carries one link and no bare token', (purpose) => {
    const { text } = buildAuthEmail(settings, purpose, token);
    expect(text).toContain(buildAuthLink(settings, purpose, token));
    expect(text.split(token)).toHaveLength(2);
    expect(text).not.toMatch(/nhập mã/i);
  });

  it('warns that a reset signs out every device and can be ignored', () => {
    const { text } = buildAuthEmail(settings, 'reset_password', token);
    expect(text).toContain('đăng xuất mọi thiết bị');
    expect(text).toContain('bỏ qua email này');
  });
});
