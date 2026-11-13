import { Module } from '@nestjs/common';
import { AppConfigReader } from './app-config.reader';
import { APP_CONFIG_REPOSITORY } from './domain/app-config.repository';
import { PrismaAppConfigRepository } from './infrastructure/prisma-app-config.repository';

/**
 * Config reading without HTTP or auth, so any module (AuthModule included) can import it
 * without a cycle. Nest shares one instance, so the reader cache is process-wide.
 */
@Module({
  providers: [
    AppConfigReader,
    { provide: APP_CONFIG_REPOSITORY, useClass: PrismaAppConfigRepository },
  ],
  exports: [AppConfigReader, APP_CONFIG_REPOSITORY],
})
export class AppConfigCoreModule {}
