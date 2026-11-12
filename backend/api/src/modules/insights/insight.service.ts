import { Inject, Injectable } from '@nestjs/common';
import { AppConfigReader } from '../app-config/app-config.reader';
import { BudgetService } from '../budgets/budget.service';
import { AutoSuggestPolicy } from '../category-suggestions/auto-suggest.policy';
import { previousPeriod, resolvePeriod, todayInTimeZone } from '../reports/domain/report';
import { buildInsights, type BudgetUsage, type Insight, type Period } from './domain/insight';
import { INSIGHT_REPOSITORY, type InsightRepository } from './domain/insight.repository';

const money = (value: bigint) => value.toString();

/** Money as strings (minor units), like every other API. */
function serialize(item: Insight) {
  switch (item.kind) {
    case 'budget_risk':
      return { ...item, spentMinor: money(item.spentMinor), limitMinor: money(item.limitMinor) };
    case 'outlier':
      return { ...item, amountMinor: money(item.amountMinor), usualMinor: money(item.usualMinor) };
    case 'category_change':
    case 'spend_trend':
      return { ...item, currentMinor: money(item.currentMinor), previousMinor: money(item.previousMinor) };
  }
}

@Injectable()
export class InsightService {
  constructor(
    @Inject(INSIGHT_REPOSITORY) private readonly repository: InsightRepository,
    private readonly policy: AutoSuggestPolicy,
    private readonly budgets: BudgetService,
    private readonly config: AppConfigReader,
  ) {}

  /** Empty list when the flag `insights` is off or the user switched suggestions off. Computed on every call, never stored. */
  async list(userId: string, now = new Date()) {
    const profile = await this.repository.profile(userId);
    if (!profile || !(await this.policy.allows('insights', userId))) {
      return { currencyCode: profile?.defaultCurrencyCode ?? null, period: null, items: [] };
    }
    const settings = {
      outlierMultiplier: await this.config.value('insights.outlierMultiplier'),
      outlierMonths: await this.config.value('insights.outlierMonths'),
      minMonths: await this.config.value('insights.minMonths'),
      budgetRiskPercent: await this.config.value('insights.budgetRiskPercent'),
      minChangePercent: await this.config.value('insights.minChangePercent'),
    };
    const today = todayInTimeZone(profile.timezone, now);
    const month = resolvePeriod({ period: 'month', on: today }, profile, now);
    const previous: Period[] = [];
    let cursor = month;
    for (let i = 0; i < settings.outlierMonths; i += 1) {
      const before = previousPeriod(cursor);
      previous.push(before);
      cursor = { ...cursor, ...before };
    }
    const from = previous.length ? previous[previous.length - 1].from : month.from;
    const ledger = await this.repository.ledger(userId, profile.defaultCurrencyCode, from, today);
    const items = buildInsights({
      today, current: { from: month.from, to: month.to }, previous, ...ledger,
      budget: await this.budgetUsage(userId, profile.defaultCurrencyCode, today), settings,
    });
    return { currencyCode: profile.defaultCurrencyCode, period: { from: month.from, to: month.to, today }, items: items.map(serialize) };
  }

  private async budgetUsage(userId: string, currencyCode: string, today: string): Promise<BudgetUsage[]> {
    const { budget } = await this.budgets.current(userId, { on: today });
    // Only the profile currency: a budget in another currency is not compared with these totals.
    if (!budget || budget.currencyCode !== currencyCode) return [];
    return [
      { categoryId: null, spentMinor: BigInt(budget.spentMinor), limitMinor: BigInt(budget.limitMinor) },
      ...budget.categories.map(line => ({ categoryId: line.categoryId ?? null, spentMinor: BigInt(line.spentMinor), limitMinor: BigInt(line.limitMinor) })),
    ];
  }
}
