import { daysInMonth, formatCalendarParts, parseCalendarParts } from '../../recurring/domain/calendar';

export const FORECAST_MAX_MONTHS = 12;
export const FORECAST_DEFAULT_MONTHS = 3;

export class ForecastError extends Error {
  constructor(readonly code: 'VALIDATION_ERROR') {
    super(code);
    this.name = 'ForecastError';
  }
}

/** One known future cash movement. Signed minor units: income positive, expense negative. */
export type ForecastEvent = { ruleId: string; date: string; amountMinor: bigint };

export type ForecastMonth = {
  month: string;
  openingMinor: bigint;
  incomeMinor: bigint;
  expenseMinor: bigint;
  closingMinor: bigint;
};

export type ForecastRange = { from: string; to: string; months: string[] };

/** From `today` through the last day of the month that is `months - 1` months ahead. */
export function forecastRange(today: string, months: number): ForecastRange {
  if (!Number.isInteger(months) || months < 1 || months > FORECAST_MAX_MONTHS) throw new ForecastError('VALIDATION_ERROR');
  const start = parseCalendarParts(today);
  const labels: string[] = [];
  let last = today;
  for (let i = 0; i < months; i++) {
    const total = start.year * 12 + (start.month - 1) + i;
    const year = Math.floor(total / 12);
    const month = (total % 12) + 1;
    labels.push(formatCalendarParts(year, month, 1).slice(0, 7));
    last = formatCalendarParts(year, month, daysInMonth(year, month));
  }
  return { from: today, to: last, months: labels };
}

/** Month-by-month balance: opening + income + expense (expense is negative) = closing. */
export function buildForecast(options: {
  startingBalanceMinor: bigint;
  events: ForecastEvent[];
  months: string[];
}): ForecastMonth[] {
  let opening = options.startingBalanceMinor;
  return options.months.map(month => {
    let income = 0n;
    let expense = 0n;
    for (const event of options.events) {
      if (event.date.slice(0, 7) !== month) continue;
      if (event.amountMinor >= 0n) income += event.amountMinor;
      else expense += event.amountMinor;
    }
    const closing = opening + income + expense;
    const row = { month, openingMinor: opening, incomeMinor: income, expenseMinor: expense, closingMinor: closing };
    opening = closing;
    return row;
  });
}
