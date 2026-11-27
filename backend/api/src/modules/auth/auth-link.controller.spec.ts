import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { AuthLinkController } from './auth-link.controller';
import { AUTH_LINK_PATHS } from './auth-link';
import { configureHttp } from '../../core/http/configure-http';

describe('email link pages', () => {
  let app: INestApplication;
  let base: string;

  beforeAll(async () => {
    const module = await Test.createTestingModule({ controllers: [AuthLinkController] }).compile();
    app = module.createNestApplication();
    app.setGlobalPrefix('api', { exclude: Object.values(AUTH_LINK_PATHS) });
    configureHttp(app);
    await app.listen(0, '127.0.0.1');
    base = await app.getUrl();
  });
  afterAll(() => app.close());

  const nonceOf = (csp: string | null) => /'nonce-([^']+)'/.exec(csp ?? '')?.[1];

  it.each(['verify-email', 'reset-password'])('/%s serves hardened HTML outside /api', async (path) => {
    const response = await fetch(`${base}/${path}?token=should-be-ignored`);
    const html = await response.text();
    expect(response.status).toBe(200);
    expect(response.headers.get('content-type')).toBe('text/html; charset=utf-8');
    expect(response.headers.get('cache-control')).toBe('no-store');
    expect(response.headers.get('referrer-policy')).toBe('no-referrer');
    expect(response.headers.get('x-robots-tag')).toContain('noindex');
    expect(response.headers.get('x-content-type-options')).toBe('nosniff');
    expect(html).toContain('<html lang="vi">');
    expect(html).not.toContain('should-be-ignored');
    expect((await fetch(`${base}/api/${path}`)).status).toBe(404);
  });

  it('replaces the helmet policy with a strict nonce policy that matches the markup', async () => {
    const response = await fetch(`${base}/verify-email`);
    const csp = response.headers.get('content-security-policy') ?? '';
    const nonce = nonceOf(csp);
    const html = await response.text();
    expect(nonce).toMatch(/^[A-Za-z0-9+/=]{20,}$/);
    expect(csp).toContain("default-src 'none'");
    expect(csp).toContain("connect-src 'self'");
    expect(csp).toContain("frame-ancestors 'none'");
    expect(csp).toContain("form-action 'none'");
    expect(csp).not.toContain('unsafe-inline');
    expect(csp.split(',')).toHaveLength(1);
    expect(html).toContain(`<script nonce="${nonce}">`);
    expect(html).toContain(`<style nonce="${nonce}">`);
    expect(html.match(/<script/g)).toHaveLength(1);
    // CSP blocks inline event handlers and style attributes without a nonce, so none may exist.
    expect(html).not.toMatch(/\son[a-z]+=/i);
    expect(html).not.toMatch(/\sstyle=/i);
  });

  it('uses a fresh nonce per response', async () => {
    const first = nonceOf((await fetch(`${base}/reset-password`)).headers.get('content-security-policy'));
    const second = nonceOf((await fetch(`${base}/reset-password`)).headers.get('content-security-policy'));
    expect(first).not.toBe(second);
  });

  it('answers HEAD without a body', async () => {
    const response = await fetch(`${base}/verify-email`, { method: 'HEAD' });
    expect(response.status).toBe(200);
    expect(await response.text()).toBe('');
  });

  it('verify page only calls the API after a tap and never on load', async () => {
    const html = await (await fetch(`${base}/verify-email`)).text();
    expect(html).toContain("addEventListener('click', verify)");
    expect(html).toContain("fetch('/api/v1/auth/verify-email'");
    expect(html).toContain("referrerPolicy: 'no-referrer'");
  });

  it('reset page builds the app link from the fragment token only', async () => {
    const html = await (await fetch(`${base}/reset-password`)).text();
    expect(html).toContain('data-scheme="freeva"');
    expect(html).toContain("'://reset-password?token='");
    expect(html).not.toContain('/api/v1/auth/reset-password');
  });
});
