import { INestApplication, ValidationPipe } from '@nestjs/common';
import helmet from 'helmet';

/** Helmet, CORS allowlist, and body validation. Does not enable Express trust proxy. */
export function configureHttp(app: INestApplication): void {
  app.use(helmet());
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
