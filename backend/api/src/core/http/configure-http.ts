import { INestApplication, ValidationPipe } from '@nestjs/common';
import { json } from 'express';
import helmet from 'helmet';

/** Helmet, CORS allowlist, and body validation. Does not enable Express trust proxy. */
export function configureHttp(app: INestApplication): void {
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
  app.enableCors({ origin: origins, credentials: true });
}
