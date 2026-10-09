import { Inject, Injectable } from '@nestjs/common';
import { REPORT_REPOSITORY, type ReportRepository } from './domain/report.repository';
import { buildCashflow, buildNetWorth, resolvePeriod } from './domain/report';
import type { CashflowQueryDto } from './report.dto';

@Injectable()
export class ReportService {
  constructor(@Inject(REPORT_REPOSITORY) private readonly repository: ReportRepository) {}

  cashflow(userId: string, query: CashflowQueryDto) {
    return this.repository.cashflow(userId, profile => resolvePeriod(query, profile)).then(result => buildCashflow(result.period, result.source));
  }

  async netWorth(userId: string) {
    return buildNetWorth(await this.repository.netWorth(userId));
  }
}
