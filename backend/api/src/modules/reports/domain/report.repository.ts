import type { InvestmentKind } from '../../investments/domain/investment';
import type { HoldingsSource, InvestmentValueHistorySource, NetWorthHistorySource } from './net-worth-history';
import type {
  TrendBucket, TrendRow, TrendSource, CategoryAggregate, CashflowSource, FlowGranularity, MerchantAggregate, NetWorthAggregate, PeriodBalanceRow, PreviousCashflow, ReportProfile, ResolvedPeriod,
} from './report';

export const REPORT_REPOSITORY = Symbol('REPORT_REPOSITORY');

export type CashflowSnapshot = {
  period: ResolvedPeriod;
  source: CashflowSource;
  previous: PreviousCashflow;
  merchants: MerchantAggregate[];
  balances: PeriodBalanceRow[];
};

export type MonthReviewSnapshot = {
  period: ResolvedPeriod;
  categories: CategoryAggregate[];
};

export type FlowSnapshot = { period: ResolvedPeriod; granularity: FlowGranularity; buckets: TrendBucket[]; rows: TrendRow[] };

export interface ReportRepository {
  cashflow(userId: string, periodOf: (profile: ReportProfile) => ResolvedPeriod): Promise<CashflowSnapshot>;
  flow(
    userId: string,
    periodOf: (profile: ReportProfile) => ResolvedPeriod,
    shape: (period: ResolvedPeriod, today: string) => { granularity: FlowGranularity; buckets: TrendBucket[] },
  ): Promise<FlowSnapshot>;
  holdings(userId: string, periodOf: (profile: ReportProfile) => ResolvedPeriod): Promise<HoldingsSource>;
  monthReview(userId: string, periodOf: (profile: ReportProfile) => ResolvedPeriod): Promise<MonthReviewSnapshot>;
  trend(userId: string, bucketsOf: (profile: ReportProfile) => TrendBucket[]): Promise<TrendSource>;
  series(userId: string, bucketsOf: (profile: ReportProfile, firstOn: string | null) => TrendBucket[]): Promise<TrendSource>;
  netWorth(userId: string): Promise<NetWorthAggregate[]>;
  netWorthHistory(userId: string, bucketsOf: (profile: ReportProfile, firstOn: string | null) => TrendBucket[]): Promise<NetWorthHistorySource>;
  investmentValueHistory(
    userId: string, filter: { kind?: InvestmentKind; investmentId?: string },
    bucketsOf: (profile: ReportProfile, firstOn: string | null) => TrendBucket[],
  ): Promise<InvestmentValueHistorySource>;
}
