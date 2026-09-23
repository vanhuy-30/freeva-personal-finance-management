import { ConfigService } from '@nestjs/config';
import { isEmail } from 'class-validator';

export interface MailSettings {
  from: string;
  host: string;
  port: number;
  secure: boolean;
  requireTLS: boolean;
  auth?: { user: string; pass: string };
  idempotencyHeader?: string;
}

/** Provider presets live here; auth and the SMTP adapter have no vendor logic. */
export function readMailSettings(config: ConfigService): MailSettings {
  const provider = config.get<string>('MAIL_PROVIDER') ?? 'smtp';
  if (!['smtp', 'resend'].includes(provider)) {
    throw new Error('MAIL_PROVIDER must be smtp or resend');
  }
  const from = (config.get<string>('MAIL_FROM') ?? config.get<string>('SMTP_FROM'))?.trim();
  const address = from?.match(/^[^<>\r\n]*<([^<>]+)>$/)?.[1] ?? from;
  if (!from || /[\r\n]/.test(from) || !address || !isEmail(address)) {
    throw new Error('MAIL_FROM must contain one valid sender address');
  }
  const resend = provider === 'resend';
  // Resend's alternate implicit-TLS port avoids Render Free's blocked 465/587.
  const port = Number(config.get<string>('SMTP_PORT') ?? (resend ? '2465' : '587'));
  if (!Number.isInteger(port) || port < 1 || port > 65535) {
    throw new Error('Invalid SMTP_PORT');
  }
  const secureValue = config.get<string>('SMTP_SECURE');
  if (secureValue !== undefined && !['true', 'false'].includes(secureValue)) {
    throw new Error('SMTP_SECURE must be true or false');
  }
  const secure = secureValue === undefined
    ? [465, 2465].includes(port)
    : secureValue === 'true';
  if (resend && (![25, 465, 587, 2465, 2587].includes(port) || secure !== [465, 2465].includes(port))) {
    throw new Error('Resend SMTP port and TLS mode do not match');
  }
  const host = resend ? 'smtp.resend.com' : config.get<string>('SMTP_HOST')?.trim();
  if (!host || /[\s/@]/.test(host)) throw new Error('SMTP_HOST is required and must be a hostname');
  const user = resend ? 'resend' : config.get<string>('SMTP_USER');
  const pass = resend ? config.get<string>('RESEND_API_KEY') : config.get<string>('SMTP_PASSWORD');
  if (resend && !pass?.trim()) throw new Error('RESEND_API_KEY is required');
  if (Boolean(user) !== Boolean(pass)) {
    throw new Error('SMTP_USER and SMTP_PASSWORD must be configured together');
  }
  const local = ['development', 'test'].includes(config.get<string>('NODE_ENV') ?? '');
  return {
    from, host, port, secure,
    requireTLS: resend || !local,
    auth: user && pass ? { user, pass } : undefined,
    ...(resend ? { idempotencyHeader: 'Resend-Idempotency-Key' } : {}),
  };
}
