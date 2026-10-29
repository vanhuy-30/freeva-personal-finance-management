export const REPORT_PERIODS = ['week', 'month', 'year', 'range'] as const;
export const TREND_PERIODS = ['week', 'month', 'year'] as const;
export const SERIES_WINDOWS = ['7d', '30d', '3m', '6m', '1y', 'all'] as const;
export type TrendPeriodKind = (typeof TREND_PERIODS)[number];
export type ReportPeriodKind = (typeof REPORT_PERIODS)[number];
export type SeriesWindow = (typeof SERIES_WINDOWS)[number];
export type ReportMoneyType = 'income' | 'expense' | 'transfer';

export class ReportError extends Error {
  constructor(readonly code: 'VALIDATION_ERROR') {
    super(code);
    this.name = 'ReportError';
  }
}

export type ReportProfile = { timezone: string; fiscalMonthStartDay: number };
export type PeriodQuery = { period: ReportPeriodKind; on?: string; from?: string; to?: string };
export type ResolvedPeriod = {
  kind: ReportPeriodKind;
  from: string;
  to: string;
  timezone: string;
  fiscalMonthStartDay: number;
};
type CalendarDate = { year: number; month: number; day: number };
export type CategoryAggregate = {
  currency: string;
  categoryId: string | null;
  parentId: string | null;
  type: 'income' | 'expense';
  total: bigint;
  count: number;
};
export type AccountRef = { accountId: string; currency: string; archived: boolean };
export type AccountMovement = { accountId: string; currency: string; type: ReportMoneyType; total: bigint };
export type CashflowSource = { categories: CategoryAggregate[]; accounts: AccountRef[]; movements: AccountMovement[] };
export type MerchantAggregate = { currency: string; merchant: string; expense: bigint; count: number };
export type PreviousCashflow = { from: string; to: string; categories: CategoryAggregate[] };
export type CashflowExtras = { previous: PreviousCashflow; merchants: MerchantAggregate[] };
export type NetWorthAggregate = { currency: string; bucket: 'asset' | 'liability'; total: bigint };

const MAX_RANGE_DAYS = 3660;
const TOP_MERCHANTS_PER_CURRENCY = 10;
const SERIES_DAY_COUNTS: Record<'7d' | '30d', number> = { '7d': 7, '30d': 30 };
const SERIES_MONTH_COUNTS: Record<'3m' | '6m' | '1y', number> = { '3m': 3, '6m': 6, '1y': 12 };
const money = (value: bigint) => value.toString();
const absMinor = (value: bigint) => (value < 0n ? -value : value);

/** Basis points of income saved (3933 = 39.33%). Null when income is not positive. */
export function savingsRateBps(netMinor: bigint, incomeMinor: bigint): number | null {
  if (incomeMinor <= 0n) return null;
  return clampBps((netMinor * 10000n) / incomeMinor);
}

/** Basis points change in |expense|; positive means more spent. Null when previous expense is zero. */
export function expenseDeltaBps(currentExpense: bigint, previousExpense: bigint): number | null {
  const previous = absMinor(previousExpense);
  if (previous === 0n) return null;
  return clampBps(((absMinor(currentExpense) - previous) * 10000n) / previous);
}

function clampBps(value: bigint): number {
  if (value > BigInt(Number.MAX_SAFE_INTEGER)) return Number.MAX_SAFE_INTEGER;
  if (value < BigInt(Number.MIN_SAFE_INTEGER)) return Number.MIN_SAFE_INTEGER;
  return Number(value);
}

function cashflowTotals(categories: CategoryAggregate[]) {
  const totals = new Map<string, { income: bigint; expense: bigint }>();
  for (const row of categories) {
    const total = totals.get(row.currency) ?? { income: 0n, expense: 0n };
    total[row.type] += row.total;
    totals.set(row.currency, total);
  }
  return totals;
}

function totalRows(totals: Map<string, { income: bigint; expense: bigint }>) {
  return [...totals].sort(([left], [right]) => left.localeCompare(right)).map(([currency, item]) => {
    const net = item.income + item.expense;
    return {
      currency,
      incomeMinor: money(item.income),
      expenseMinor: money(item.expense),
      netMinor: money(net),
      savingsRateBps: savingsRateBps(net, item.income),
    };
  });
}

/** Adjacent previous period of the same kind. Range shifts back by its inclusive length. */
export function previousPeriod(period: ResolvedPeriod): { from: string; to: string } {
  const from = parseDate(period.from);
  const before = addDays(from, -1);
  if (period.kind === 'week') return weekBounds(before);
  if (period.kind === 'month') return monthBounds(before, period.fiscalMonthStartDay);
  if (period.kind === 'year') {
    const year = from.year - 1;
    if (year < 1) throw new ReportError('VALIDATION_ERROR');
    return { from: formatDate({ year, month: 1, day: 1 }), to: formatDate({ year, month: 12, day: 31 }) };
  }
  const length = daysApart(from, parseDate(period.to)) + 1;
  const previousTo = before;
  const previousFrom = addDays(previousTo, 1 - length);
  return { from: formatDate(previousFrom), to: formatDate(previousTo) };
}

export function todayInTimeZone(timeZone: string, now: Date): string {
  const parts = new Intl.DateTimeFormat('en-US', { timeZone, year: 'numeric', month: '2-digit', day: '2-digit' }).formatToParts(now);
  const value = (type: Intl.DateTimeFormatPartTypes) => parts.find(part => part.type === type)?.value;
  const year = value('year');
  const month = value('month');
  const day = value('day');
  if (!year || !month || !day) throw new ReportError('VALIDATION_ERROR');
  return `${year}-${month}-${day}`;
}

export function resolvePeriod(query: PeriodQuery, profile: ReportProfile, now = new Date()): ResolvedPeriod {
  if (profile.fiscalMonthStartDay < 1 || profile.fiscalMonthStartDay > 28) throw new Error('Invalid fiscal month');
  const anchor = query.period === 'range' ? undefined : query.on ?? todayInTimeZone(profile.timezone, now);
  if (query.period === 'range') {
    if (query.on !== undefined || query.from === undefined || query.to === undefined) throw new ReportError('VALIDATION_ERROR');
    const from = parseDate(query.from);
    const to = parseDate(query.to);
    const apart = daysApart(from, to);
    if (apart < 0 || apart > MAX_RANGE_DAYS) throw new ReportError('VALIDATION_ERROR');
    return { kind: 'range', from: formatDate(from), to: formatDate(to), timezone: profile.timezone, fiscalMonthStartDay: profile.fiscalMonthStartDay };
  }
  if (query.from !== undefined || query.to !== undefined || anchor === undefined) throw new ReportError('VALIDATION_ERROR');
  const date = parseDate(anchor);
  const bounds = periodBounds(query.period, date, profile.fiscalMonthStartDay);
  return { kind: query.period, ...bounds, timezone: profile.timezone, fiscalMonthStartDay: profile.fiscalMonthStartDay };
}

const TREND_BUCKETS: Record<TrendPeriodKind, number> = { week: 8, month: 6, year: 5 };
export type TrendBucket = { from: string; to: string };
export type TrendRow = { index: number; currency: string; type: 'income' | 'expense'; total: bigint };
export type TrendSource = { buckets: TrendBucket[]; rows: TrendRow[]; firstOn: string | null };

/** Oldest-first bucket bounds ending at the period that contains the anchor. */
export function trendBuckets(query: { period: TrendPeriodKind; on?: string }, profile: ReportProfile, now = new Date()): TrendBucket[] {
  if (profile.fiscalMonthStartDay < 1 || profile.fiscalMonthStartDay > 28) throw new Error('Invalid fiscal month');
  let anchor = parseDate(query.on ?? todayInTimeZone(profile.timezone, now));
  const buckets: TrendBucket[] = [];
  for (let step = 0; step < TREND_BUCKETS[query.period]; step++) {
    const bounds = periodBounds(query.period, anchor, profile.fiscalMonthStartDay);
    buckets.unshift(bounds);
    if (step + 1 < TREND_BUCKETS[query.period]) {
      const before = parseDate(bounds.from);
      if (before.year <= 100) break; // Date.UTC maps years 0-99 to 19xx, so history stops here
      anchor = addDays(before, -1);
    }
  }
  return buckets;
}

export function buildTrend(period: TrendPeriodKind, source: TrendSource) {
  const firstYear = source.firstOn === null ? null : Number(source.firstOn.slice(0, 4));
  const keep = (bucket: TrendBucket, index: number) =>
    period !== 'year' || index === source.buckets.length - 1 || (firstYear !== null && Number(bucket.to.slice(0, 4)) >= firstYear);
  const totals = source.buckets.map(() => new Map<string, { income: bigint; expense: bigint }>());
  for (const row of source.rows) {
    const item = totals[row.index]?.get(row.currency) ?? { income: 0n, expense: 0n };
    item[row.type] += row.total;
    totals[row.index]?.set(row.currency, item);
  }
  return {
    kind: period,
    buckets: source.buckets.flatMap((bucket, index) => keep(bucket, index) ? [{
      from: bucket.from, to: bucket.to,
      totals: [...totals[index]].sort(([left], [right]) => left.localeCompare(right)).map(([currency, item]) => ({
        currency, incomeMinor: money(item.income), expenseMinor: money(item.expense),
      })),
    }] : []),
  };
}

export function buildCashflow(period: ResolvedPeriod, source: CashflowSource, extras?: CashflowExtras) {
  const previous = extras?.previous ?? { from: period.from, to: period.to, categories: [] };
  const merchants = extras?.merchants ?? [];
  const totals = cashflowTotals(source.categories);
  const previousTotals = cashflowTotals(previous.categories);
  const categories = new Map<string, { categoryId: string | null; parentId: string | null; currency: string; income: bigint; expense: bigint; count: number }>();
  for (const row of source.categories) {
    const key = `${row.currency}\0${row.categoryId ?? ''}`;
    const item = categories.get(key) ?? { categoryId: row.categoryId, parentId: row.parentId, currency: row.currency, income: 0n, expense: 0n, count: 0 };
    item[row.type] += row.total;
    item.count += row.count;
    categories.set(key, item);
  }
  const accounts = new Map<string, { accountId: string; currency: string; income: bigint; expense: bigint; transfer: bigint; include: boolean }>();
  for (const account of source.accounts) {
    accounts.set(account.accountId, { accountId: account.accountId, currency: account.currency, income: 0n, expense: 0n, transfer: 0n, include: !account.archived });
  }
  for (const row of source.movements) {
    const item = accounts.get(row.accountId) ?? { accountId: row.accountId, currency: row.currency, income: 0n, expense: 0n, transfer: 0n, include: true };
    if (row.type === 'transfer') item.transfer += row.total;
    else item[row.type] += row.total;
    item.include = true;
    accounts.set(row.accountId, item);
  }
  const currencies = new Set([...totals.keys(), ...previousTotals.keys()]);
  return {
    period,
    totals: totalRows(totals),
    byCategory: [...categories.values()].filter(item => item.income !== 0n || item.expense !== 0n).sort(compareCategory).map(item => ({
      categoryId: item.categoryId, parentId: item.parentId, currency: item.currency, incomeMinor: money(item.income), expenseMinor: money(item.expense), transactionCount: item.count,
    })),
    byAccount: [...accounts.values()].filter(item => item.include).sort(compareAccount).map(item => ({
      accountId: item.accountId, currency: item.currency, incomeMinor: money(item.income), expenseMinor: money(item.expense),
      transferMinor: money(item.transfer), netMinor: money(item.income + item.expense + item.transfer),
    })),
    comparison: {
      from: previous.from,
      to: previous.to,
      totals: totalRows(previousTotals),
      expenseDeltaBps: [...currencies].sort((left, right) => left.localeCompare(right)).map(currency => ({
        currency,
        deltaBps: expenseDeltaBps(totals.get(currency)?.expense ?? 0n, previousTotals.get(currency)?.expense ?? 0n),
      })),
    },
    topMerchants: topMerchantRows(merchants),
  };
}

function topMerchantRows(rows: MerchantAggregate[]) {
  const grouped = new Map<string, { currency: string; merchant: string; expense: bigint; count: number }>();
  for (const row of rows) {
    const key = `${row.currency}\0${row.merchant}`;
    const item = grouped.get(key) ?? { currency: row.currency, merchant: row.merchant, expense: 0n, count: 0 };
    item.expense += row.expense;
    item.count += row.count;
    grouped.set(key, item);
  }
  const byCurrency = new Map<string, typeof grouped extends Map<string, infer V> ? V[] : never>();
  for (const item of grouped.values()) {
    const list = byCurrency.get(item.currency) ?? [];
    list.push(item);
    byCurrency.set(item.currency, list);
  }
  return [...byCurrency.keys()].sort((left, right) => left.localeCompare(right)).flatMap(currency => {
    const list = byCurrency.get(currency) ?? [];
    list.sort((left, right) => {
      const leftAbs = absMinor(left.expense);
      const rightAbs = absMinor(right.expense);
      if (rightAbs > leftAbs) return 1;
      if (rightAbs < leftAbs) return -1;
      return left.merchant.localeCompare(right.merchant);
    });
    return list.slice(0, TOP_MERCHANTS_PER_CURRENCY).map(item => ({
      currency: item.currency,
      merchant: item.merchant,
      expenseMinor: money(item.expense),
      transactionCount: item.count,
    }));
  });
}

/** Oldest-first series buckets for 7d/30d days, fiscal months, or all calendar years. */
export function seriesBuckets(
  query: { window: SeriesWindow; on?: string },
  profile: ReportProfile,
  firstOn: string | null = null,
  now = new Date(),
): TrendBucket[] {
  if (profile.fiscalMonthStartDay < 1 || profile.fiscalMonthStartDay > 28) throw new Error('Invalid fiscal month');
  const anchor = parseDate(query.on ?? todayInTimeZone(profile.timezone, now));
  if (query.window === '7d' || query.window === '30d') {
    const count = SERIES_DAY_COUNTS[query.window];
    const buckets: TrendBucket[] = [];
    for (let step = count - 1; step >= 0; step--) {
      const day = addDays(anchor, -step);
      const value = formatDate(day);
      buckets.push({ from: value, to: value });
    }
    return buckets;
  }
  if (query.window === '3m' || query.window === '6m' || query.window === '1y') {
    const count = SERIES_MONTH_COUNTS[query.window];
    let cursor = anchor;
    const buckets: TrendBucket[] = [];
    for (let step = 0; step < count; step++) {
      const bounds = monthBounds(cursor, profile.fiscalMonthStartDay);
      buckets.unshift(bounds);
      if (step + 1 < count) {
        const before = parseDate(bounds.from);
        if (before.year <= 100) break;
        cursor = addDays(before, -1);
      }
    }
    return buckets;
  }
  const endYear = anchor.year;
  const startYear = firstOn === null ? endYear : Math.max(100, Number(firstOn.slice(0, 4)));
  if (startYear > endYear) return [{ from: formatDate({ year: endYear, month: 1, day: 1 }), to: formatDate({ year: endYear, month: 12, day: 31 }) }];
  const buckets: TrendBucket[] = [];
  for (let year = startYear; year <= endYear; year++) {
    buckets.push({ from: formatDate({ year, month: 1, day: 1 }), to: formatDate({ year, month: 12, day: 31 }) });
  }
  return buckets;
}

export function buildSeries(window: SeriesWindow, source: TrendSource) {
  const totals = source.buckets.map(() => new Map<string, { income: bigint; expense: bigint }>());
  for (const row of source.rows) {
    const item = totals[row.index]?.get(row.currency) ?? { income: 0n, expense: 0n };
    item[row.type] += row.total;
    totals[row.index]?.set(row.currency, item);
  }
  return {
    window,
    buckets: source.buckets.map((bucket, index) => ({
      from: bucket.from,
      to: bucket.to,
      totals: [...(totals[index] ?? [])].sort(([left], [right]) => left.localeCompare(right)).map(([currency, item]) => ({
        currency, incomeMinor: money(item.income), expenseMinor: money(item.expense),
      })),
    })),
  };
}

export function buildNetWorth(rows: NetWorthAggregate[]) {
  const totals = new Map<string, { assets: bigint; liabilities: bigint }>();
  for (const row of rows) {
    const item = totals.get(row.currency) ?? { assets: 0n, liabilities: 0n };
    if (row.bucket === 'asset') item.assets += row.total;
    else item.liabilities += row.total;
    totals.set(row.currency, item);
  }
  return {
    items: [...totals].sort(([left], [right]) => left.localeCompare(right)).map(([currency, item]) => ({
      currency, assetsMinor: money(item.assets), liabilitiesMinor: money(item.liabilities), netWorthMinor: money(item.assets + item.liabilities),
    })),
  };
}

function compareCategory(left: { currency: string; categoryId: string | null }, right: { currency: string; categoryId: string | null }) {
  const currency = left.currency.localeCompare(right.currency);
  if (currency !== 0) return currency;
  if (left.categoryId === right.categoryId) return 0;
  if (left.categoryId === null) return 1;
  if (right.categoryId === null) return -1;
  return left.categoryId.localeCompare(right.categoryId);
}

function compareAccount(left: { currency: string; accountId: string }, right: { currency: string; accountId: string }) {
  return left.currency.localeCompare(right.currency) || left.accountId.localeCompare(right.accountId);
}

function parseDate(value: string): CalendarDate {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value);
  if (!match) throw new ReportError('VALIDATION_ERROR');
  const date = { year: Number(match[1]), month: Number(match[2]), day: Number(match[3]) };
  if (date.year < 1 || date.year > 9999 || date.month < 1 || date.month > 12 || date.day < 1 || date.day > daysInMonth(date.year, date.month)) {
    throw new ReportError('VALIDATION_ERROR');
  }
  return date;
}

function formatDate(date: CalendarDate): string {
  return `${String(date.year).padStart(4, '0')}-${String(date.month).padStart(2, '0')}-${String(date.day).padStart(2, '0')}`;
}

function daysInMonth(year: number, month: number): number {
  return new Date(Date.UTC(year, month, 0)).getUTCDate();
}

function utcTime(date: CalendarDate): number {
  return Date.UTC(date.year, date.month - 1, date.day);
}

function fromUtc(time: number): CalendarDate {
  const date = new Date(time);
  return { year: date.getUTCFullYear(), month: date.getUTCMonth() + 1, day: date.getUTCDate() };
}

function addDays(date: CalendarDate, days: number): CalendarDate {
  const next = fromUtc(utcTime(date) + days * 86_400_000);
  if (next.year < 1 || next.year > 9999) throw new ReportError('VALIDATION_ERROR');
  return next;
}

function daysApart(from: CalendarDate, to: CalendarDate): number {
  return Math.round((utcTime(to) - utcTime(from)) / 86_400_000);
}

function shiftMonth(year: number, month: number, delta: number): CalendarDate {
  const index = year * 12 + (month - 1) + delta;
  const nextYear = Math.floor(index / 12);
  return { year: nextYear, month: index - nextYear * 12 + 1, day: 1 };
}

function periodBounds(period: Exclude<ReportPeriodKind, 'range'>, date: CalendarDate, startDay: number) {
  if (period === 'week') return weekBounds(date);
  if (period === 'year') return { from: formatDate({ year: date.year, month: 1, day: 1 }), to: formatDate({ year: date.year, month: 12, day: 31 }) };
  return monthBounds(date, startDay);
}

function weekBounds(date: CalendarDate) {
  const weekday = new Date(utcTime(date)).getUTCDay();
  const from = addDays(date, weekday === 0 ? -6 : 1 - weekday);
  return { from: formatDate(from), to: formatDate(addDays(from, 6)) };
}

function monthBounds(date: CalendarDate, startDay: number) {
  const start = date.day >= startDay ? { year: date.year, month: date.month } : shiftMonth(date.year, date.month, -1);
  const next = shiftMonth(start.year, start.month, 1);
  if (start.year < 1 || next.year > 9999) throw new ReportError('VALIDATION_ERROR');
  return { from: formatDate({ ...start, day: startDay }), to: formatDate(addDays({ ...next, day: startDay }, -1)) };
}
