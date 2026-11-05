import type {
  TrendBucket, TrendSource, CategoryAggregate, CashflowSource, MerchantAggregate, NetWorthAggregate, PreviousCashflow, ReportProfile, ResolvedPeriod,
} from './report';

export const REPORT_REPOSITORY = Symbol('REPORT_REPOSITORY');

export type CashflowSnapshot = {
  period: ResolvedPeriod;
  source: CashflowSource;
  previous: PreviousCashflow;
  merchants: MerchantAggregate[];
};

export type MonthReviewSnapshot = {
  period: ResolvedPeriod;
  categories: CategoryAggregate[];
};

export interface ReportRepository {
  cashflow(userId: string, periodOf: (profile: ReportProfile) => ResolvedPeriod): Promise<CashflowSnapshot>;
  monthReview(userId: string, periodOf: (profile: ReportProfile) => ResolvedPeriod): Promise<MonthReviewSnapshot>;
  trend(userId: string, bucketsOf: (profile: ReportProfile) => TrendBucket[]): Promise<TrendSource>;
  series(userId: string, bucketsOf: (profile: ReportProfile, firstOn: string | null) => TrendBucket[]): Promise<TrendSource>;
  netWorth(userId: string): Promise<NetWorthAggregate[]>;
}
