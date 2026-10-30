import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { FxRateModule } from '../fx-rates/fx-rate.module';
import { REPORT_REPOSITORY } from './domain/report.repository';
import { PrismaReportRepository } from './infrastructure/prisma-report.repository';
import { ReportController } from './report.controller';
import { ReportService } from './report.service';

@Module({
  imports: [AuthModule, FxRateModule],
  controllers: [ReportController],
  providers: [ReportService, { provide: REPORT_REPOSITORY, useClass: PrismaReportRepository }],
})
export class ReportModule {}
