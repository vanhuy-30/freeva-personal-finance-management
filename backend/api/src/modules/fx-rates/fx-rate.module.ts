import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { FX_RATE_REPOSITORY } from './domain/fx-rate.repository';
import { FxRateController } from './fx-rate.controller';
import { FxRateService } from './fx-rate.service';
import { PrismaFxRateRepository } from './infrastructure/prisma-fx-rate.repository';

@Module({
  imports: [AuthModule],
  controllers: [FxRateController],
  providers: [FxRateService, { provide: FX_RATE_REPOSITORY, useClass: PrismaFxRateRepository }],
  exports: [FxRateService],
})
export class FxRateModule {}
