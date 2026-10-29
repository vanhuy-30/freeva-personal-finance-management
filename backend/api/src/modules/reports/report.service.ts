import { Inject, Injectable } from '@nestjs/common';
import { REPORT_REPOSITORY, type ReportRepository } from './domain/report.repository';
import {
  buildCashflow, buildMonthReview, buildNetWorth, buildSeries, buildTrend, resolvePeriod, seriesBuckets, trendBuckets,
} from './domain/report';
import type { CashflowQueryDto, MonthReviewQueryDto, SeriesQueryDto, TrendQueryDto } from './report.dto';

@Injectable()
export class ReportService {
  constructor(@Inject(REPORT_REPOSITORY) private readonly repository: ReportRepository) {}

  cashflow(userId: string, query: CashflowQueryDto) {
    return this.repository.cashflow(userId, profile => resolvePeriod(query, profile)).then(result =>
      buildCashflow(result.period, result.source, { previous: result.previous, merchants: result.merchants }),
    );
  }

  monthReview(userId: string, query: MonthReviewQueryDto) {
    return this.repository
      .monthReview(userId, profile => resolvePeriod({ period: 'month', on: query.on }, profile))
      .then(result => buildMonthReview(result.period, { categories: result.categories, accounts: [], movements: [] }));
  }

  async trend(userId: string, query: TrendQueryDto) {
    return buildTrend(query.period, await this.repository.trend(userId, profile => trendBuckets(query, profile)));
  }

  async series(userId: string, query: SeriesQueryDto) {
    return buildSeries(
      query.window,
      await this.repository.series(userId, (profile, firstOn) => seriesBuckets(query, profile, firstOn)),
    );
  }

  async netWorth(userId: string) {
    return buildNetWorth(await this.repository.netWorth(userId));
  }
}
