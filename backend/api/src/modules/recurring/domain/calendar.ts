/** Calendar-date math for recurring rules. Dates are YYYY-MM-DD; no wall-clock offsets. */

export const RECURRING_UNITS = ['day', 'week', 'month', 'year'] as const;
export type RecurringUnit = (typeof RECURRING_UNITS)[number];

export class RecurringCalendarError extends Error {
  constructor(readonly code: 'VALIDATION_ERROR') {
    super(code);
  }
}

export function parseCalendarParts(value: string): { year: number; month: number; day: number } {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) throw new RecurringCalendarError('VALIDATION_ERROR');
  const year = Number(value.slice(0, 4));
  const month = Number(value.slice(5, 7));
  const day = Number(value.slice(8, 10));
  const check = new Date(Date.UTC(year, month - 1, day));
  if (
    !Number.isFinite(check.getTime()) ||
    check.getUTCFullYear() !== year ||
    check.getUTCMonth() !== month - 1 ||
    check.getUTCDate() !== day ||
    value < '0001-01-01'
  ) {
    throw new RecurringCalendarError('VALIDATION_ERROR');
  }
  return { year, month, day };
}

export function formatCalendarParts(year: number, month: number, day: number): string {
  return `${String(year).padStart(4, '0')}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
}

export function daysInMonth(year: number, month: number): number {
  return new Date(Date.UTC(year, month, 0)).getUTCDate();
}

/** Preferred day-of-month for monthly/yearly clamping (from the rule start date). */
export function anchorDay(startDate: string): number {
  return parseCalendarParts(startDate).day;
}

/**
 * Advance `from` by `interval` units. For month/year, keep `preferredDay` clamped to the
 * last day of the target month (31 Jan → 28/29 Feb → 31 Mar).
 */
export function addInterval(
  from: string,
  unit: RecurringUnit,
  interval: number,
  preferredDay: number,
): string {
  if (!Number.isInteger(interval) || interval < 1 || interval > 366) {
    throw new RecurringCalendarError('VALIDATION_ERROR');
  }
  if (!Number.isInteger(preferredDay) || preferredDay < 1 || preferredDay > 31) {
    throw new RecurringCalendarError('VALIDATION_ERROR');
  }
  const { year, month, day } = parseCalendarParts(from);
  if (unit === 'day') {
    const date = new Date(Date.UTC(year, month - 1, day));
    date.setUTCDate(date.getUTCDate() + interval);
    return formatCalendarParts(date.getUTCFullYear(), date.getUTCMonth() + 1, date.getUTCDate());
  }
  if (unit === 'week') {
    return addInterval(from, 'day', 7 * interval, preferredDay);
  }
  if (unit === 'month') {
    const total = year * 12 + (month - 1) + interval;
    const nextYear = Math.floor(total / 12);
    const nextMonth = (total % 12) + 1;
    const nextDay = Math.min(preferredDay, daysInMonth(nextYear, nextMonth));
    return formatCalendarParts(nextYear, nextMonth, nextDay);
  }
  const nextYear = year + interval;
  const nextDay = Math.min(preferredDay, daysInMonth(nextYear, month));
  return formatCalendarParts(nextYear, month, nextDay);
}

export function compareCalendar(a: string, b: string): number {
  parseCalendarParts(a);
  parseCalendarParts(b);
  return a < b ? -1 : a > b ? 1 : 0;
}

/** Dates due on or before `today`, stopping at `endDate` when set. Cap protects runaway catch-up. */
export function dueDates(options: {
  nextExecutionDate: string;
  startDate: string;
  endDate: string | null;
  today: string;
  unit: RecurringUnit;
  interval: number;
  active: boolean;
  limit?: number;
}): string[] {
  const { nextExecutionDate, startDate, endDate, today, unit, interval, active } = options;
  const limit = options.limit ?? 36;
  if (!active) return [];
  parseCalendarParts(today);
  const preferred = anchorDay(startDate);
  const dates: string[] = [];
  let cursor = nextExecutionDate;
  for (let i = 0; i < limit; i++) {
    if (compareCalendar(cursor, today) > 0) break;
    if (endDate !== null && compareCalendar(cursor, endDate) > 0) break;
    dates.push(cursor);
    cursor = addInterval(cursor, unit, interval, preferred);
  }
  return dates;
}
