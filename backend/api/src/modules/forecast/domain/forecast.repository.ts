export const FORECAST_REPOSITORY = Symbol('FORECAST_REPOSITORY');

export type ForecastRule = {
  id: string;
  mode: 'auto' | 'remind';
  type: string;
  amountMinor: bigint;
  currencyCode: string;
  unit: 'day' | 'week' | 'month' | 'year';
  interval: number;
  startDate: string;
  endDate: string | null;
  nextExecutionDate: string;
};

export type ForecastSource = {
  timezone: string;
  today: string;
  defaultCurrencyCode: string;
  /** Sum of non-archived, non-credit wallets per currency. */
  balanceByCurrency: Map<string, bigint>;
  rules: ForecastRule[];
};

export interface ForecastRepository {
  load(userId: string, now?: Date): Promise<ForecastSource>;
}
