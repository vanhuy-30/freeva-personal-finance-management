import { Inject, Injectable } from '@nestjs/common';
import { FxRateService } from '../fx-rates/fx-rate.service';
import { REPORT_REPOSITORY, type ReportRepository } from './domain/report.repository';
import {
  buildCashflow, buildFlow, buildMonthReview, buildNetWorth, buildSeries, buildTrend, convertCashflow, convertNetWorth, flowBuckets, resolvePeriod, seriesBuckets, trendBuckets,
} from './domain/report';
import { buildHoldings, buildInvestmentValueHistory, buildNetWorthHistory } from './domain/net-worth-history';
import type { CashflowQueryDto, InvestmentHistoryQueryDto, PeriodQueryDto, MonthReviewQueryDto, SeriesQueryDto, TrendQueryDto } from './report.dto';

@Injectable()
export class ReportService {
  constructor(
    @Inject(REPORT_REPOSITORY) private readonly repository: ReportRepository,
    private readonly rates: FxRateService,
  ) {}

  async cashflow(userId: string, query: CashflowQueryDto) {
    const result = await this.repository.cashflow(userId, profile => resolvePeriod(query, profile));
    const report = buildCashflow(result.period, result.source, { previous: result.previous, merchants: result.merchants, balances: result.balances });
    if (!query.displayCurrency) return report;
    return { ...report, converted: convertCashflow(report.totals, query.displayCurrency, await this.rates.book(userId)) };
  }

  async flow(userId: string, query: PeriodQueryDto) {
    const result = await this.repository.flow(userId, profile => resolvePeriod(query, profile), flowBuckets);
    return buildFlow(result.period, result.granularity, result);
  }

  async holdings(userId: string, query: PeriodQueryDto) {
    return buildHoldings(await this.repository.holdings(userId, profile => resolvePeriod(query, profile)));
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

  async netWorthHistory(userId: string, query: SeriesQueryDto) {
    return buildNetWorthHistory(
      query.window,
      await this.repository.netWorthHistory(userId, (profile, firstOn) => seriesBuckets(query, profile, firstOn)),
    );
  }

  async investmentHistory(userId: string, query: InvestmentHistoryQueryDto) {
    const filter = { kind: query.kind, investmentId: query.investmentId };
    return buildInvestmentValueHistory(
      query.window,
      await this.repository.investmentValueHistory(userId, filter, (profile, firstOn) => seriesBuckets(query, profile, firstOn)),
    );
  }

  async netWorth(userId: string, displayCurrency?: string) {
    const report = buildNetWorth(await this.repository.netWorth(userId));
    if (!displayCurrency) return report;
    return { ...report, converted: convertNetWorth(report.items, displayCurrency, await this.rates.book(userId)) };
  }
}
