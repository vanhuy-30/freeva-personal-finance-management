/**
 * BE-P5-E06: two projections from the user's own ledger. Pure. They are predictions, not
 * recorded numbers: the app says so on screen. Nothing here writes anything.
 */

// ---------------------------------------------------------------- spending this month

export interface ForecastTransaction {
  type: 'expense' | 'refund';
  /** Magnitude in minor units. */
  amountMinor: bigint;
  categoryId: string | null;
  occurredOn: string;
  /** Written by a recurring rule: already known ahead, so not part of the day-to-day pace. */
  recurring?: boolean;
}

export interface ForecastCategory { id: string; name: string; parentId: string | null; iconToken: string | null; colorToken: string | null }

export interface SpendSettings { minDays: number; mediumRiskPercent: number; highRiskPercent: number }

export interface SpendInput {
  today: string;
  /** Current fiscal month. */
  current: { from: string; to: string };
  /** Previous fiscal month (whole). */
  previous: { from: string; to: string };
  transactions: ForecastTransaction[];
  categories: ForecastCategory[];
  /** Whole-month budget in the profile currency, if any. */
  budgetLimitMinor: bigint | null;
  settings: SpendSettings;
}

export type SpendRisk = 'low' | 'medium' | 'high';

export interface SpendForecast {
  status: 'ok' | 'insufficient';
  daysElapsed: number;
  daysInPeriod: number;
  spentMinor: bigint;
  /** Null while `insufficient`. */
  forecastMinor: bigint | null;
  dailyAverageMinor: bigint;
  budgetLimitMinor: bigint | null;
  risk: SpendRisk | null;
  /** forecast − budget when above it. */
  overBudgetMinor: bigint | null;
  /** (budget − spent) / days left; null without budget, when already over, or on the last day. */
  dailyAllowanceMinor: bigint | null;
  /** Whole previous fiscal month, for the comparison without a budget. */
  previousMonthMinor: bigint;
  /** Spent so far, one point per elapsed day. */
  cumulative: Array<{ date: string; spentMinor: bigint }>;
  /** Top-level categories with the most spending this month, at most 3. */
  topCategories: Array<{ category: Omit<ForecastCategory, 'parentId'>; spentMinor: bigint; sharePercent: number }>;
}

const DAY = 86_400_000;
const time = (date: string) => Date.parse(`${date}T00:00:00Z`);
const days = (from: string, to: string) => Math.round((time(to) - time(from)) / DAY) + 1;
const addDays = (date: string, n: number) => new Date(time(date) + n * DAY).toISOString().slice(0, 10);
const signed = (row: ForecastTransaction) => (row.type === 'refund' ? -row.amountMinor : row.amountMinor);
const inside = (date: string, from: string, to: string) => date >= from && date <= to;

export function spendForecast(input: SpendInput): SpendForecast {
  const daysInPeriod = days(input.current.from, input.current.to);
  const daysElapsed = Math.min(daysInPeriod, Math.max(1, days(input.current.from, input.today)));
  const now = input.transactions.filter(row => inside(row.occurredOn, input.current.from, input.today));
  const spentMinor = now.reduce((sum, row) => sum + signed(row), 0n);
  const previousMonthMinor = input.transactions
    .filter(row => inside(row.occurredOn, input.previous.from, input.previous.to))
    .reduce((sum, row) => sum + signed(row), 0n);

  const byDay = new Map<string, bigint>();
  for (const row of now) byDay.set(row.occurredOn, (byDay.get(row.occurredOn) ?? 0n) + signed(row));
  const cumulative: SpendForecast['cumulative'] = [];
  let running = 0n;
  for (let i = 0; i < daysElapsed; i += 1) {
    const date = addDays(input.current.from, i);
    running += byDay.get(date) ?? 0n;
    cumulative.push({ date, spentMinor: running });
  }

  const byId = new Map(input.categories.map(c => [c.id, c]));
  const root = (id: string | null) => {
    let category = id ? byId.get(id) : undefined;
    for (let guard = 0; category?.parentId && guard < 10; guard += 1) category = byId.get(category.parentId) ?? category;
    return category;
  };
  const perRoot = new Map<string, bigint>();
  for (const row of now) {
    const category = root(row.categoryId);
    if (category) perRoot.set(category.id, (perRoot.get(category.id) ?? 0n) + signed(row));
  }
  const topCategories = [...perRoot]
    .filter(([, amount]) => amount > 0n)
    .sort((a, b) => (b[1] > a[1] ? 1 : b[1] < a[1] ? -1 : 0))
    .slice(0, 3)
    .map(([id, amount]) => {
      const { parentId: _parent, ...category } = byId.get(id)!;
      return { category, spentMinor: amount, sharePercent: spentMinor > 0n ? Number((amount * 100n) / spentMinor) : 0 };
    });

  const positive = spentMinor > 0n ? spentMinor : 0n;
  const dailyAverageMinor = positive / BigInt(daysElapsed);
  const limit = input.budgetLimitMinor !== null && input.budgetLimitMinor > 0n ? input.budgetLimitMinor : null;
  const daysLeft = daysInPeriod - daysElapsed;
  const dailyAllowanceMinor = limit !== null && daysLeft > 0 && limit > positive ? (limit - positive) / BigInt(daysLeft) : null;
  const base = {
    daysElapsed, daysInPeriod, spentMinor, dailyAverageMinor, budgetLimitMinor: limit, dailyAllowanceMinor,
    previousMonthMinor, cumulative, topCategories,
  };
  if (daysElapsed < input.settings.minDays) {
    return { ...base, status: 'insufficient', forecastMinor: null, risk: null, overBudgetMinor: null };
  }
  const forecastMinor = (positive * BigInt(daysInPeriod)) / BigInt(daysElapsed);
  let risk: SpendRisk | null = null;
  if (limit !== null) {
    const used = forecastMinor * 100n;
    risk = used > limit * BigInt(input.settings.highRiskPercent) ? 'high'
      : used >= limit * BigInt(input.settings.mediumRiskPercent) ? 'medium' : 'low';
  }
  return {
    ...base, status: 'ok', forecastMinor, risk,
    overBudgetMinor: limit !== null && forecastMinor > limit ? forecastMinor - limit : null,
  };
}

// ---------------------------------------------------------------- balance at the end of the month

/** One known movement still to come: income positive, expense negative. */
export interface BalanceEvent { date: string; amountMinor: bigint }

export interface BalanceOutlookInput {
  today: string;
  /** Last day of the current fiscal month. */
  periodTo: string;
  /** Sum of the user's non-credit wallets in the profile currency. */
  balanceMinor: bigint;
  /** Recurring income and expenses from `today` through `periodTo`. */
  events: BalanceEvent[];
  /** Day-to-day spending per day (recurring excluded); null while the pace is unknown. */
  dailySpendMinor: bigint | null;
}

export interface BalanceOutlook {
  balanceMinor: bigint;
  /** Recurring income still to come this month. */
  incomeAheadMinor: bigint;
  /** Recurring expenses still to come this month (magnitude). */
  billsAheadMinor: bigint;
  /** Day-to-day spending expected over the rest of the month; null while unknown. */
  dailySpendMinor: bigint | null;
  variableAheadMinor: bigint | null;
  endMinor: bigint;
  /** End balance if day-to-day spending runs 25% above / below the pace. */
  endLowMinor: bigint;
  endHighMinor: bigint;
  /** First day the projected balance goes below zero; null when it stays at or above. */
  runsOutOn: string | null;
}

/** How far day-to-day spending may stray from its pace; drives the low/high end balance. */
export const VARIABLE_SPREAD_PERCENT = 25n;

/**
 * Average day-to-day spend so far this month: expenses and refunds that no recurring rule wrote,
 * over the days elapsed. Never negative.
 */
export function dailySpend(input: SpendInput): bigint {
  const daysElapsed = Math.min(days(input.current.from, input.current.to), Math.max(1, days(input.current.from, input.today)));
  const total = input.transactions
    .filter(row => !row.recurring && inside(row.occurredOn, input.current.from, input.today))
    .reduce((sum, row) => sum + signed(row), 0n);
  return total > 0n ? total / BigInt(daysElapsed) : 0n;
}

/**
 * Balance walked day by day to the end of the month: wallet balance, plus recurring income and minus
 * recurring bills on their dates, minus the day-to-day pace on every day after today. A prediction.
 */
export function balanceOutlook(input: BalanceOutlookInput): BalanceOutlook {
  const byDate = new Map<string, bigint>();
  let incomeAheadMinor = 0n;
  let billsAheadMinor = 0n;
  for (const event of input.events) {
    if (event.date < input.today || event.date > input.periodTo) continue;
    byDate.set(event.date, (byDate.get(event.date) ?? 0n) + event.amountMinor);
    if (event.amountMinor > 0n) incomeAheadMinor += event.amountMinor; else billsAheadMinor -= event.amountMinor;
  }
  const pace = input.dailySpendMinor ?? 0n;
  const span = days(input.today, input.periodTo);
  let running = input.balanceMinor;
  let runsOutOn: string | null = null;
  for (let i = 0; i < span; i += 1) {
    const date = addDays(input.today, i);
    running += byDate.get(date) ?? 0n;
    if (i > 0) running -= pace;
    if (runsOutOn === null && running < 0n) runsOutOn = date;
  }
  const variableAheadMinor = input.dailySpendMinor === null ? null : pace * BigInt(Math.max(0, span - 1));
  const spread = ((variableAheadMinor ?? 0n) * VARIABLE_SPREAD_PERCENT) / 100n;
  return {
    balanceMinor: input.balanceMinor, incomeAheadMinor, billsAheadMinor, dailySpendMinor: input.dailySpendMinor,
    variableAheadMinor, endMinor: running, endLowMinor: running - spread, endHighMinor: running + spread, runsOutOn,
  };
}

// ---------------------------------------------------------------- goal reach date

export interface GoalEntryRow { kind: 'contribute' | 'withdraw'; amountMinor: bigint; occurredOn: string }

export interface GoalForecastInput {
  today: string;
  targetMinor: bigint;
  currentMinor: bigint;
  /** YYYY-MM-DD or null. */
  targetDate: string | null;
  entries: GoalEntryRow[];
  /** Completed calendar months to average over (`goalForecast.months`). */
  months: number;
}

export type GoalForecast =
  | { status: 'reached' }
  | { status: 'insufficient'; months: number }
  | {
    status: 'ok';
    months: number;
    /** Net contributions (góp − rút) per month over the last `months` completed months. */
    averageMonthlyMinor: bigint;
    /** YYYY-MM of the month the last needed contribution lands in. */
    expectedMonth: string;
    /** YYYY-MM of the target date, or null. */
    targetMonth: string | null;
    /** expected − target in months: positive late, negative early, 0 on time; null without a target date. */
    monthsLate: number | null;
  };

const monthIndex = (date: string) => Number(date.slice(0, 4)) * 12 + Number(date.slice(5, 7)) - 1;
const monthText = (index: number) => `${String(Math.floor(index / 12)).padStart(4, '0')}-${String((index % 12) + 1).padStart(2, '0')}`;

export function goalForecast(input: GoalForecastInput): GoalForecast {
  if (input.currentMinor >= input.targetMinor) return { status: 'reached' };
  const thisMonth = monthIndex(input.today);
  // Completed months only: the month in progress would pull the average down before the user has contributed.
  const window = input.entries.filter(entry => {
    const m = monthIndex(entry.occurredOn);
    return m < thisMonth && m >= thisMonth - input.months;
  });
  const net = window.reduce((sum, entry) => sum + (entry.kind === 'contribute' ? entry.amountMinor : -entry.amountMinor), 0n);
  const average = net / BigInt(input.months);
  if (average <= 0n) return { status: 'insufficient', months: input.months };
  const remaining = input.targetMinor - input.currentMinor;
  const needed = Number((remaining + average - 1n) / average);
  const expected = thisMonth + needed - 1;
  const target = input.targetDate ? monthIndex(input.targetDate) : null;
  return {
    status: 'ok', months: input.months, averageMonthlyMinor: average, expectedMonth: monthText(expected),
    targetMonth: target === null ? null : monthText(target), monthsLate: target === null ? null : expected - target,
  };
}
