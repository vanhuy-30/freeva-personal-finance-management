export const REPORT_PERIODS = ['week', 'month', 'range'] as const;
export type ReportPeriodKind = (typeof REPORT_PERIODS)[number];
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
};
export type AccountRef = { accountId: string; currency: string; archived: boolean };
export type AccountMovement = { accountId: string; currency: string; type: ReportMoneyType; total: bigint };
export type CashflowSource = { categories: CategoryAggregate[]; accounts: AccountRef[]; movements: AccountMovement[] };
export type NetWorthAggregate = { currency: string; bucket: 'asset' | 'liability'; total: bigint };

const MAX_RANGE_DAYS = 3660;
const money = (value: bigint) => value.toString();

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
  const bounds = query.period === 'week' ? weekBounds(date) : monthBounds(date, profile.fiscalMonthStartDay);
  return { kind: query.period, ...bounds, timezone: profile.timezone, fiscalMonthStartDay: profile.fiscalMonthStartDay };
}

export function buildCashflow(period: ResolvedPeriod, source: CashflowSource) {
  const totals = new Map<string, { income: bigint; expense: bigint }>();
  const categories = new Map<string, { categoryId: string | null; parentId: string | null; currency: string; income: bigint; expense: bigint }>();
  for (const row of source.categories) {
    const key = `${row.currency}\0${row.categoryId ?? ''}`;
    const item = categories.get(key) ?? { categoryId: row.categoryId, parentId: row.parentId, currency: row.currency, income: 0n, expense: 0n };
    item[row.type] += row.total;
    categories.set(key, item);
    const total = totals.get(row.currency) ?? { income: 0n, expense: 0n };
    total[row.type] += row.total;
    totals.set(row.currency, total);
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
  return {
    period,
    totals: [...totals].sort(([left], [right]) => left.localeCompare(right)).map(([currency, item]) => ({
      currency, incomeMinor: money(item.income), expenseMinor: money(item.expense), netMinor: money(item.income + item.expense),
    })),
    byCategory: [...categories.values()].filter(item => item.income !== 0n || item.expense !== 0n).sort(compareCategory).map(item => ({
      categoryId: item.categoryId, parentId: item.parentId, currency: item.currency, incomeMinor: money(item.income), expenseMinor: money(item.expense),
    })),
    byAccount: [...accounts.values()].filter(item => item.include).sort(compareAccount).map(item => ({
      accountId: item.accountId, currency: item.currency, incomeMinor: money(item.income), expenseMinor: money(item.expense),
      transferMinor: money(item.transfer), netMinor: money(item.income + item.expense + item.transfer),
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
