import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { StaffAuthGuard } from '../staff-auth/staff-auth.guard';
import { AdminAppConfigController } from './admin-app-config.controller';
import { AppConfigController } from './app-config.controller';
import { AppConfigService } from './app-config.service';
import { APP_CONFIG_REPOSITORY } from './domain/app-config.repository';
import { FeatureGuard } from './feature.guard';
import { PrismaAppConfigRepository } from './infrastructure/prisma-app-config.repository';

@Module({
  imports: [AuthModule],
  controllers: [AppConfigController, AdminAppConfigController],
  providers: [
    AppConfigService,
    FeatureGuard,
    StaffAuthGuard,
    { provide: APP_CONFIG_REPOSITORY, useClass: PrismaAppConfigRepository },
  ],
  exports: [AppConfigService, FeatureGuard],
})
export class AppConfigModule {}
