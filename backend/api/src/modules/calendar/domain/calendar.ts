import { daysInMonth, formatCalendarParts, parseCalendarParts, RecurringCalendarError } from '../../recurring/domain/calendar';
import { todayInTimeZone } from '../../reports/domain/report';
import type { TransactionType } from '../../transactions/domain/transaction';
import type { BillAmountKind } from '../../bills/domain/bill';
import { billFlags } from '../../bills/domain/bill';

export class CalendarError extends Error {
  constructor(readonly code: 'VALIDATION_ERROR') {
    super(code);
    this.name = 'CalendarError';
  }
}

export type CalendarTransactionItem = {
  id: string;
  type: TransactionType;
  amountMinor: bigint;
  currencyCode: string;
  categoryName: string | null;
  transferGroupId: string | null;
  occurredOn: string;
};

export type CalendarRecurringItem = {
  id: string;
  type: TransactionType;
  amountMinor: bigint;
  currencyCode: string;
  categoryName: string | null;
  occurredOn: string;
};

export type CalendarBillItem = {
  id: string;
  name: string;
  dueOn: string;
  amountMinor: bigint;
  amountKind: BillAmountKind;
  currencyCode: string;
  paidTransactionId: string | null;
};

export type CalendarDay = {
  date: string;
  transactions: CalendarTransactionItem[];
  recurring: CalendarRecurringItem[];
  bills: Array<CalendarBillItem & { paid: boolean; overdue: boolean }>;
};

export type CalendarMonth = {
  month: string;
  timezone: string;
  today: string;
  days: CalendarDay[];
};

export type CalendarMonthBounds = { month: string; from: string; to: string };

/** Civil calendar month `YYYY-MM` → inclusive date bounds. */
export function parseMonth(month: string): CalendarMonthBounds {
  if (!/^\d{4}-\d{2}$/.test(month)) throw new CalendarError('VALIDATION_ERROR');
  const year = Number(month.slice(0, 4));
  const monthNum = Number(month.slice(5, 7));
  if (!Number.isInteger(year) || year < 1 || monthNum < 1 || monthNum > 12) {
    throw new CalendarError('VALIDATION_ERROR');
  }
  try {
    parseCalendarParts(`${month}-01`);
  } catch (error) {
    if (error instanceof RecurringCalendarError) throw new CalendarError('VALIDATION_ERROR');
    throw error;
  }
  const last = daysInMonth(year, monthNum);
  return {
    month,
    from: formatCalendarParts(year, monthNum, 1),
    to: formatCalendarParts(year, monthNum, last),
  };
}

export function profileToday(timezone: string, now = new Date()): string {
  try {
    return todayInTimeZone(timezone, now);
  } catch {
    throw new CalendarError('VALIDATION_ERROR');
  }
}

/**
 * One calendar row per transfer group (or single leg). Prefer the lowest id as the
 * representative so retries stay stable.
 */
export function dedupeTransferLegs(rows: CalendarTransactionItem[]): CalendarTransactionItem[] {
  const seen = new Set<string>();
  const out: CalendarTransactionItem[] = [];
  const ordered = [...rows].sort((a, b) => {
    if (a.occurredOn !== b.occurredOn) return a.occurredOn < b.occurredOn ? -1 : 1;
    return a.id < b.id ? -1 : a.id > b.id ? 1 : 0;
  });
  for (const row of ordered) {
    const key = row.transferGroupId ?? row.id;
    if (seen.has(key)) continue;
    seen.add(key);
    out.push(row);
  }
  return out;
}

export function buildMonth(options: {
  month: string;
  timezone: string;
  today: string;
  transactions: CalendarTransactionItem[];
  recurring: CalendarRecurringItem[];
  bills: CalendarBillItem[];
}): CalendarMonth {
  const bounds = parseMonth(options.month);
  const byDate = new Map<string, CalendarDay>();

  const day = (date: string): CalendarDay => {
    let entry = byDate.get(date);
    if (!entry) {
      entry = { date, transactions: [], recurring: [], bills: [] };
      byDate.set(date, entry);
    }
    return entry;
  };

  for (const row of dedupeTransferLegs(options.transactions)) {
    if (row.occurredOn < bounds.from || row.occurredOn > bounds.to) continue;
    day(row.occurredOn).transactions.push(row);
  }
  for (const row of options.recurring) {
    if (row.occurredOn < bounds.from || row.occurredOn > bounds.to) continue;
    day(row.occurredOn).recurring.push(row);
  }
  for (const bill of options.bills) {
    if (bill.dueOn < bounds.from || bill.dueOn > bounds.to) continue;
    const flags = billFlags(
      { dueOn: new Date(`${bill.dueOn}T00:00:00.000Z`), paidTransactionId: bill.paidTransactionId },
      options.today,
    );
    day(bill.dueOn).bills.push({ ...bill, paid: flags.paid, overdue: flags.overdue });
  }

  const days = [...byDate.values()].sort((a, b) => (a.date < b.date ? -1 : 1));
  for (const entry of days) {
    entry.transactions.sort((a, b) => (a.id < b.id ? -1 : 1));
    entry.recurring.sort((a, b) => (a.id < b.id ? -1 : a.id > b.id ? 1 : a.occurredOn.localeCompare(b.occurredOn)));
    entry.bills.sort((a, b) => (a.id < b.id ? -1 : 1));
  }

  return {
    month: bounds.month,
    timezone: options.timezone,
    today: options.today,
    days,
  };
}

export function money(value: bigint): string {
  return value.toString();
}
