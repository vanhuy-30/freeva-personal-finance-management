import { INestApplication, ValidationPipe } from '@nestjs/common';
import { json } from 'express';
import helmet from 'helmet';

/**
 * Number of reverse proxies in front of the API (`TRUST_PROXY_HOPS`, default 0).
 * Express then takes the client IP that many hops back in `X-Forwarded-For` and
 * ignores anything a client prepends, so per-IP auth limits see the real client
 * instead of the proxy (SEC-P6-002). Invalid values fail start-up.
 */
export function trustProxyHops(value = process.env.TRUST_PROXY_HOPS): number {
  if (value === undefined || value.trim() === '') return 0;
  if (!/^\d$/.test(value.trim())) {
    throw new Error('TRUST_PROXY_HOPS must be an integer from 0 to 9');
  }
  return Number(value.trim());
}

/** Helmet, CORS allowlist, trust proxy hops, and body validation. */
export function configureHttp(app: INestApplication): void {
  const hops = trustProxyHops();
  if (hops > 0) app.getHttpAdapter().getInstance().set('trust proxy', hops);
  app.use(helmet());
  // CSV import sends the file as JSON text; this route alone may exceed the default 100 kb body limit.
  app.use('/api/v1/transactions/import', json({ limit: '2mb' }));
  // Nest skips its own JSON parser once any `jsonParser` middleware exists (the one above), which
  // left every other route with an unparsed body. Add the default 100 kb parser back for all routes;
  // it does nothing when the import parser already read the body.
  app.use(json());
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );
  const origins = (process.env.CORS_ORIGINS ?? 'http://localhost:3001')
    .split(',')
    .map((value) => value.trim());
  // Auth is a Bearer header only (no cookies), so credentialed CORS is not needed.
  app.enableCors({ origin: origins });
}
