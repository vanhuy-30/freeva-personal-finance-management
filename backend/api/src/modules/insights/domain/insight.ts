/**
 * BE-P5-E04: rule-based insights from the user's own ledger. Pure: the service loads rows,
 * this decides what is worth saying. Every number comes from transactions or the budget;
 * nothing is invented. One item per kind, in priority order.
 */

export type InsightKind = 'budget_risk' | 'outlier' | 'category_change' | 'spend_trend';

export interface InsightCategory {
  id: string;
  name: string;
  parentId: string | null;
  iconToken: string | null;
  colorToken: string | null;
}

/** Expense or refund in the profile currency, not deleted. */
export interface InsightTransaction {
  id: string;
  type: 'expense' | 'refund';
  /** Magnitude in minor units (refunds reduce spend). */
  amountMinor: bigint;
  categoryId: string | null;
  merchant: string | null;
  occurredOn: string;
}

export interface Period { from: string; to: string }

export interface BudgetUsage {
  /** Null for the whole-month budget. */
  categoryId: string | null;
  spentMinor: bigint;
  limitMinor: bigint;
}

export interface InsightSettings {
  outlierMultiplier: number;
  outlierMonths: number;
  minMonths: number;
  budgetRiskPercent: number;
  minChangePercent: number;
}

export interface InsightInput {
  today: string;
  /** Current fiscal month. */
  current: Period;
  /** The `outlierMonths` fiscal months before it, newest first. */
  previous: Period[];
  transactions: InsightTransaction[];
  categories: InsightCategory[];
  budget: BudgetUsage[];
  settings: InsightSettings;
}

type CategoryView = Pick<InsightCategory, 'id' | 'name' | 'iconToken' | 'colorToken'>;

export type Insight =
  | { kind: 'budget_risk'; category: CategoryView | null; spentMinor: bigint; limitMinor: bigint; percent: number; daysLeft: number }
  | { kind: 'outlier'; category: CategoryView; transactionId: string; merchant: string | null; occurredOn: string; amountMinor: bigint; usualMinor: bigint; times: number }
  | { kind: 'category_change'; category: CategoryView; currentMinor: bigint; previousMinor: bigint; changePercent: number | null; direction: 'up' | 'down' }
  | { kind: 'spend_trend'; currentMinor: bigint; previousMinor: bigint; changePercent: number | null; direction: 'up' | 'down'; days: number };

const DAY = 86_400_000;
const toTime = (date: string) => Date.parse(`${date}T00:00:00Z`);
const addDays = (date: string, days: number) => new Date(toTime(date) + days * DAY).toISOString().slice(0, 10);
const daysBetween = (from: string, to: string) => Math.round((toTime(to) - toTime(from)) / DAY);
const within = (date: string, period: Period) => date >= period.from && date <= period.to;
const signed = (row: InsightTransaction) => (row.type === 'refund' ? -row.amountMinor : row.amountMinor);
/** Rounded percent change, never from a zero base. */
const percentChange = (current: bigint, previous: bigint) => Number(((current - previous) * 1000n) / previous) / 10;

export function buildInsights(input: InsightInput): Insight[] {
  const byId = new Map(input.categories.map(c => [c.id, c]));
  const view = (c: InsightCategory): CategoryView => ({ id: c.id, name: c.name, iconToken: c.iconToken, colorToken: c.colorToken });
  /** Top-level category: children roll up so "Ăn uống" includes "Cà phê" when it sits under it. */
  const root = (id: string | null): InsightCategory | null => {
    let category = id ? byId.get(id) : undefined;
    for (let guard = 0; category?.parentId && guard < 10; guard += 1) category = byId.get(category.parentId) ?? category;
    return category ?? null;
  };

  const elapsed = daysBetween(input.current.from, input.today) + 1;
  const sameSoFar = (period: Period): Period => {
    const to = addDays(period.from, elapsed - 1);
    return { from: period.from, to: to < period.to ? to : period.to };
  };
  const now: Period = { from: input.current.from, to: input.today };
  const last = input.previous[0] ? sameSoFar(input.previous[0]) : null;
  const spend = (period: Period | null, rootId?: string) => input.transactions
    .filter(row => period && within(row.occurredOn, period) && (rootId === undefined || root(row.categoryId)?.id === rootId))
    .reduce((sum, row) => sum + signed(row), 0n);
  const monthsWithData = (rootId?: string) => input.previous.filter(period =>
    input.transactions.some(row => row.type === 'expense' && within(row.occurredOn, period) && (rootId === undefined || root(row.categoryId)?.id === rootId)),
  ).length;
  const enoughHistory = monthsWithData() >= input.settings.minMonths;
  const items: Insight[] = [];

  // 1. Budget nearly used: the line with the highest share at or above the threshold.
  const risky = input.budget
    .filter(line => line.limitMinor > 0n && line.spentMinor * 100n >= line.limitMinor * BigInt(input.settings.budgetRiskPercent))
    .map(line => ({ line, share: Number((line.spentMinor * 1000n) / line.limitMinor) / 10 }))
    .filter(({ line }) => line.categoryId === null || byId.has(line.categoryId))
    .sort((a, b) => b.share - a.share || Number(a.line.categoryId === null) - Number(b.line.categoryId === null));
  if (risky[0]) {
    const { line, share } = risky[0];
    items.push({
      kind: 'budget_risk', category: line.categoryId ? view(byId.get(line.categoryId)!) : null,
      spentMinor: line.spentMinor, limitMinor: line.limitMinor, percent: Math.floor(share),
      daysLeft: Math.max(0, daysBetween(input.today, input.current.to)),
    });
  }

  // 2. One expense far above what is usual for its category over the last months.
  const usualByRoot = new Map<string, { sum: bigint; count: bigint }>();
  for (const other of input.transactions) {
    if (other.type !== 'expense' || !input.previous.some(period => within(other.occurredOn, period))) continue;
    const id = root(other.categoryId)?.id;
    if (!id) continue;
    const entry = usualByRoot.get(id) ?? { sum: 0n, count: 0n };
    usualByRoot.set(id, { sum: entry.sum + other.amountMinor, count: entry.count + 1n });
  }
  const roomyRoots = new Set([...usualByRoot.keys()].filter(id => monthsWithData(id) >= input.settings.minMonths));
  let best: { row: InsightTransaction; category: InsightCategory; usual: bigint; ratio: number } | null = null;
  for (const row of input.transactions) {
    if (row.type !== 'expense' || !within(row.occurredOn, now)) continue;
    const category = root(row.categoryId);
    if (!category || !roomyRoots.has(category.id)) continue;
    const { sum, count } = usualByRoot.get(category.id)!;
    const usual = sum / count;
    if (usual <= 0n) continue;
    const ratio = Number((row.amountMinor * 100n) / usual) / 100;
    if (ratio >= input.settings.outlierMultiplier && (!best || ratio > best.ratio)) best = { row, category, usual, ratio };
  }
  if (best) {
    items.push({
      kind: 'outlier', category: view(best.category), transactionId: best.row.id, merchant: best.row.merchant,
      occurredOn: best.row.occurredOn, amountMinor: best.row.amountMinor, usualMinor: best.usual, times: Math.floor(best.ratio),
    });
  }

  // 3. The category that moved most against the same days of last month (needs a base last month).
  if (last) {
    const roots = new Set(input.transactions.map(row => root(row.categoryId)?.id).filter((id): id is string => !!id));
    const moves = [...roots].map(id => ({ id, current: spend(now, id), previous: spend(last, id) }))
      .filter(move => move.previous > 0n && move.current >= 0n)
      .map(move => ({ ...move, delta: move.current - move.previous, change: percentChange(move.current, move.previous) }));
    const up = moves.filter(m => m.change >= input.settings.minChangePercent).sort((a, b) => (b.delta > a.delta ? 1 : b.delta < a.delta ? -1 : 0))[0];
    const down = moves.filter(m => m.change <= -input.settings.minChangePercent).sort((a, b) => (a.delta > b.delta ? 1 : a.delta < b.delta ? -1 : 0))[0];
    const pick = up ?? down;
    if (pick) {
      items.push({
        kind: 'category_change', category: view(byId.get(pick.id)!), currentMinor: pick.current, previousMinor: pick.previous,
        changePercent: enoughHistory ? Math.round(pick.change) : null, direction: pick.delta >= 0n ? 'up' : 'down',
      });
    }
  }

  // 4. Total spending so far against the same days of last month.
  if (last) {
    const current = spend(now);
    const previous = spend(last);
    if (previous > 0n && current >= 0n) {
      const change = percentChange(current, previous);
      if (Math.abs(change) >= input.settings.minChangePercent) {
        items.push({
          kind: 'spend_trend', currentMinor: current, previousMinor: previous,
          changePercent: enoughHistory ? Math.round(change) : null, direction: current >= previous ? 'up' : 'down', days: elapsed,
        });
      }
    }
  }
  return items;
}
