import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { LoggerModule } from 'nestjs-pino';
import { pinoRedactOptions } from './core/logging/pino-redact';
import { PrismaModule } from './infrastructure/prisma/prisma.module';
import { AdminUserLookupModule } from './modules/admin-user-lookup/admin-user-lookup.module';
import { HealthModule } from './modules/health/health.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: ['.env', '../../.env'],
    }),
    LoggerModule.forRoot({
      pinoHttp: {
        level: process.env.LOG_LEVEL ?? 'info',
        redact: pinoRedactOptions,
      },
    }),
    PrismaModule,
    HealthModule,
    AdminUserLookupModule,
  ],
})
export class AppModule {}
