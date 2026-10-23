import type { TrendBucket, TrendSource, CashflowSource, NetWorthAggregate, ReportProfile, ResolvedPeriod } from './report';

export const REPORT_REPOSITORY = Symbol('REPORT_REPOSITORY');

export interface ReportRepository {
  cashflow(userId: string, periodOf: (profile: ReportProfile) => ResolvedPeriod): Promise<{ period: ResolvedPeriod; source: CashflowSource }>;
  trend(userId: string, bucketsOf: (profile: ReportProfile) => TrendBucket[]): Promise<TrendSource>;
  netWorth(userId: string): Promise<NetWorthAggregate[]>;
}
