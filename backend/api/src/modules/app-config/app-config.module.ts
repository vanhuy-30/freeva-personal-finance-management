import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { StaffAuthGuard } from '../staff-auth/staff-auth.guard';
import { AdminAppConfigController } from './admin-app-config.controller';
import { AppConfigController } from './app-config.controller';
import { AppConfigService } from './app-config.service';
import { FeatureGuard } from './feature.guard';
import { AppConfigCoreModule } from './app-config-core.module';

@Module({
  imports: [AuthModule, AppConfigCoreModule],
  controllers: [AppConfigController, AdminAppConfigController],
  providers: [
    AppConfigService,
    FeatureGuard,
    StaffAuthGuard,
  ],
  exports: [AppConfigService, FeatureGuard, AppConfigCoreModule],
})
export class AppConfigModule {}
