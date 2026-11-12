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
