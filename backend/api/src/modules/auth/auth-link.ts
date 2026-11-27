import { ConfigService } from '@nestjs/config';
import type { TokenPurpose } from './domain/auth.repository';

/** Injection token for the validated link settings (see `readAppLinkSettings`). */
export const APP_LINK_SETTINGS = Symbol('APP_LINK_SETTINGS');

export interface AppLinkSettings {
  /** Origin (plus optional path prefix) that serves the link pages, without a trailing slash. */
  baseUrl: string;
}

/** Single-use token lifetimes; the email text and the stored expiry both read this. */
export const TOKEN_TTL_MINUTES: Record<TokenPurpose, number> = {
  verify_email: 24 * 60,
  reset_password: 30,
};

/**
 * Public paths of the link pages. They keep the same shape whether the API serves them (staging)
 * or a future freeva web app does, so only `APP_LINK_BASE_URL` changes when the web app exists.
 */
export const AUTH_LINK_PATHS: Record<TokenPurpose, string> = {
  verify_email: 'verify-email',
  reset_password: 'reset-password',
};

const LOCAL_BASE_URL = 'http://localhost:3000';

/**
 * Reads `APP_LINK_BASE_URL`. HTTPS is mandatory (mail clients drop other schemes); plain http is
 * accepted only for localhost in development/test, where the variable may also be left unset.
 * Anything else fails start-up so a bad value never reaches a sent email.
 */
export function readAppLinkSettings(config: ConfigService): AppLinkSettings {
  const local = ['development', 'test'].includes(config.get<string>('NODE_ENV') ?? '');
  const raw = config.get<string>('APP_LINK_BASE_URL')?.trim();
  if (!raw) {
    if (local) return { baseUrl: LOCAL_BASE_URL };
    throw new Error('APP_LINK_BASE_URL is required');
  }
  let url: URL;
  try {
    url = new URL(raw);
  } catch {
    throw new Error('APP_LINK_BASE_URL must be an absolute URL');
  }
  const loopback = ['localhost', '127.0.0.1', '[::1]'].includes(url.hostname);
  const allowed = url.protocol === 'https:' || (url.protocol === 'http:' && local && loopback);
  if (!allowed) throw new Error('APP_LINK_BASE_URL must use https');
  if (url.username || url.password) throw new Error('APP_LINK_BASE_URL must not contain credentials');
  if (url.search || url.hash) throw new Error('APP_LINK_BASE_URL must not contain a query or fragment');
  return { baseUrl: `${url.origin}${url.pathname.replace(/\/+$/, '')}` };
}

/**
 * Link for an emailed token. The token sits in the URL fragment, which browsers never send to a
 * server, so it stays out of access logs, proxies and Referer headers.
 */
export function buildAuthLink(
  settings: AppLinkSettings,
  purpose: TokenPurpose,
  token: string,
): string {
  return `${settings.baseUrl}/${AUTH_LINK_PATHS[purpose]}#token=${encodeURIComponent(token)}`;
}

function lifetimeLabel(minutes: number): string {
  return minutes % 60 === 0 ? `${minutes / 60} giờ` : `${minutes} phút`;
}

/** Subject and plain-text body for an auth email. Never includes the bare token. */
export function buildAuthEmail(
  settings: AppLinkSettings,
  purpose: TokenPurpose,
  token: string,
): { subject: string; text: string } {
  const link = buildAuthLink(settings, purpose, token);
  const lifetime = lifetimeLabel(TOKEN_TTL_MINUTES[purpose]);
  if (purpose === 'verify_email') {
    return {
      subject: 'Freeva — Xác thực email',
      text:
        `Xác nhận email cho tài khoản Freeva của bạn:\n\n${link}\n\n` +
        `Link có hiệu lực tối đa ${lifetime} và chỉ dùng được một lần. ` +
        'Nếu bạn không đăng ký Freeva, hãy bỏ qua email này.',
    };
  }
  return {
    subject: 'Freeva — Đặt lại mật khẩu',
    text:
      `Đặt lại mật khẩu Freeva:\n\n${link}\n\n` +
      'Hãy mở link trên điện thoại đã cài Freeva. ' +
      `Link có hiệu lực tối đa ${lifetime} và chỉ dùng được một lần. ` +
      'Đặt lại mật khẩu sẽ đăng xuất mọi thiết bị. ' +
      'Nếu bạn không yêu cầu, hãy bỏ qua email này — mật khẩu hiện tại không đổi.',
  };
}
