import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import { AppConfigReader } from '../app-config/app-config.reader';
import { BudgetService } from '../budgets/budget.service';
import { AutoSuggestPolicy } from '../category-suggestions/auto-suggest.policy';
import { previousPeriod, resolvePeriod, todayInTimeZone } from '../reports/domain/report';
import { goalForecast, spendForecast, type GoalForecast, type SpendForecast } from './domain/spend-forecast';
import { SPEND_FORECAST_REPOSITORY, type SpendForecastRepository } from './domain/spend-forecast.repository';

const money = (value: bigint | null) => (value === null ? null : value.toString());

function spendView(result: SpendForecast) {
  return {
    ...result,
    spentMinor: money(result.spentMinor),
    forecastMinor: money(result.forecastMinor),
    dailyAverageMinor: money(result.dailyAverageMinor),
    budgetLimitMinor: money(result.budgetLimitMinor),
    overBudgetMinor: money(result.overBudgetMinor),
    dailyAllowanceMinor: money(result.dailyAllowanceMinor),
    previousMonthMinor: money(result.previousMonthMinor),
    cumulative: result.cumulative.map(point => ({ date: point.date, spentMinor: money(point.spentMinor) })),
    topCategories: result.topCategories.map(item => ({ ...item, spentMinor: money(item.spentMinor) })),
  };
}

function goalView(result: GoalForecast) {
  return result.status === 'ok' ? { ...result, averageMonthlyMinor: money(result.averageMonthlyMinor) } : result;
}

/** First day of the month `back` calendar months before `today`'s month. */
function monthsBack(today: string, back: number): string {
  const index = Number(today.slice(0, 4)) * 12 + Number(today.slice(5, 7)) - 1 - back;
  return `${String(Math.floor(index / 12)).padStart(4, '0')}-${String((index % 12) + 1).padStart(2, '0')}-01`;
}

@Injectable()
export class SpendForecastService {
  constructor(
    @Inject(SPEND_FORECAST_REPOSITORY) private readonly repository: SpendForecastRepository,
    private readonly policy: AutoSuggestPolicy,
    private readonly budgets: BudgetService,
    private readonly config: AppConfigReader,
  ) {}

  /** `forecast: null` when the flag `forecast` is off or the user switched suggestions off. */
  async spending(userId: string, now = new Date()) {
    const profile = await this.repository.profile(userId);
    if (!profile || !(await this.policy.allows('forecast', userId))) return { currencyCode: profile?.defaultCurrencyCode ?? null, period: null, forecast: null };
    const today = todayInTimeZone(profile.timezone, now);
    const month = resolvePeriod({ period: 'month', on: today }, profile, now);
    const previous = previousPeriod(month);
    const ledger = await this.repository.ledger(userId, profile.defaultCurrencyCode, previous.from, today);
    const { budget } = await this.budgets.current(userId, { on: today });
    const result = spendForecast({
      today, current: { from: month.from, to: month.to }, previous, ...ledger,
      // A budget in another currency is not compared with these totals.
      budgetLimitMinor: budget && budget.currencyCode === profile.defaultCurrencyCode ? BigInt(budget.limitMinor) : null,
      settings: {
        minDays: await this.config.value('spendForecast.minDays'),
        mediumRiskPercent: await this.config.value('spendForecast.mediumRiskPercent'),
        highRiskPercent: await this.config.value('spendForecast.highRiskPercent'),
      },
    });
    return { currencyCode: profile.defaultCurrencyCode, period: { from: month.from, to: month.to, today }, forecast: spendView(result) };
  }

  /** `forecast: null` when forecasts are off for the user; 404 when the goal is not theirs. */
  async goal(userId: string, goalId: string, now = new Date()) {
    const profile = await this.repository.profile(userId);
    if (!profile) throw new NotFoundException({ error: { code: 'GOAL_NOT_FOUND', message: 'Goal not found', details: [] } });
    const allowed = await this.policy.allows('forecast', userId);
    const today = todayInTimeZone(profile.timezone, now);
    const months = await this.config.value('goalForecast.months');
    const goal = await this.repository.goal(userId, goalId, monthsBack(today, months));
    if (!goal) throw new NotFoundException({ error: { code: 'GOAL_NOT_FOUND', message: 'Goal not found', details: [] } });
    if (!allowed) return { forecast: null };
    return { forecast: goalView(goalForecast({ today, ...goal, months })) };
  }
}
