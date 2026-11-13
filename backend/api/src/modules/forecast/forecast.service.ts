import { AppConfigReader } from '../app-config/app-config.reader';
import { Inject, Injectable } from '@nestjs/common';
import { occurrencesInRange } from '../recurring/domain/calendar';
import {
  buildForecast,
  forecastRange,
  type ForecastEvent,
} from './domain/forecast';
import { FORECAST_REPOSITORY, type ForecastRepository } from './domain/forecast.repository';

export type ForecastInput = {
  months?: number;
  currencyCode?: string;
  startingBalanceMinor?: string;
  excludeRuleIds?: string[];
};

@Injectable()
export class ForecastService {
  constructor(
    @Inject(FORECAST_REPOSITORY) private readonly repository: ForecastRepository,
    private readonly config: AppConfigReader,
  ) {}

  async forecast(userId: string, input: ForecastInput, now = new Date()) {
    const source = await this.repository.load(userId, now);
    const range = forecastRange(source.today, input.months ?? (await this.config.value('forecast.defaultMonths')));
    const currencyCode = input.currencyCode ?? source.defaultCurrencyCode;
    const excluded = new Set(input.excludeRuleIds ?? []);
    const overridden = input.startingBalanceMinor !== undefined;
    const startingBalanceMinor = overridden
      ? BigInt(input.startingBalanceMinor as string)
      : source.balanceByCurrency.get(currencyCode) ?? 0n;

    const events: ForecastEvent[] = [];
    const included: string[] = [];
    const otherCurrencyRuleIds: string[] = [];
    const excludedRuleIds: string[] = [];
    for (const rule of source.rules) {
      // Transfers net to zero inside the user's own wallets; adjustments/debt are not known future flows.
      if (rule.type !== 'income' && rule.type !== 'expense') continue;
      if (rule.currencyCode !== currencyCode) {
        otherCurrencyRuleIds.push(rule.id);
        continue;
      }
      if (excluded.has(rule.id)) {
        excludedRuleIds.push(rule.id);
        continue;
      }
      const dates = occurrencesInRange({
        nextExecutionDate: rule.nextExecutionDate,
        startDate: rule.startDate,
        endDate: rule.endDate,
        rangeFrom: range.from,
        rangeTo: range.to,
        unit: rule.unit,
        interval: rule.interval,
        active: true,
      });
      if (dates.length) included.push(rule.id);
      for (const date of dates) events.push({ ruleId: rule.id, date, amountMinor: rule.amountMinor });
    }

    const months = buildForecast({ startingBalanceMinor, events, months: range.months });
    return {
      timezone: source.timezone,
      currencyCode,
      from: range.from,
      to: range.to,
      startingBalanceMinor: startingBalanceMinor.toString(),
      months: months.map(row => ({
        month: row.month,
        openingMinor: row.openingMinor.toString(),
        incomeMinor: row.incomeMinor.toString(),
        expenseMinor: row.expenseMinor.toString(),
        closingMinor: row.closingMinor.toString(),
      })),
      assumptions: {
        balanceSource: overridden ? 'user' : 'wallets',
        includesCreditWallets: false,
        includesOneOffSpending: false,
        includedRuleIds: included,
        excludedRuleIds,
        otherCurrencyRuleIds,
      },
    };
  }
}
