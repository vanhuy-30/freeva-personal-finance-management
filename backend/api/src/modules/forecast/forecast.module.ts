import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { FORECAST_REPOSITORY } from './domain/forecast.repository';
import { ForecastController } from './forecast.controller';
import { ForecastService } from './forecast.service';
import { PrismaForecastRepository } from './infrastructure/prisma-forecast.repository';

@Module({
  imports: [AuthModule],
  controllers: [ForecastController],
  providers: [
    ForecastService,
    { provide: FORECAST_REPOSITORY, useClass: PrismaForecastRepository },
  ],
})
export class ForecastModule {}
