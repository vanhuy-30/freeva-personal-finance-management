import './instrument';

import { HttpAdapterHost, NestFactory } from '@nestjs/core';
import { Logger } from 'nestjs-pino';
import { AppModule } from './app.module';
import { AUTH_LINK_PATHS } from './modules/auth/auth-link';
import { configureHttp } from './core/http/configure-http';
import { SentryExceptionFilter } from './core/sentry/sentry-exception.filter';

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create(AppModule, { bufferLogs: true });
  app.useLogger(app.get(Logger));
  // Email link pages keep their public URL shape (`/verify-email`, `/reset-password`) outside `/api`.
  app.setGlobalPrefix('api', { exclude: Object.values(AUTH_LINK_PATHS) });
  configureHttp(app);
  const { httpAdapter } = app.get(HttpAdapterHost);
  app.useGlobalFilters(new SentryExceptionFilter(httpAdapter));

  const port = Number(process.env.PORT ?? 3000);
  await app.listen(port);
}

void bootstrap();
