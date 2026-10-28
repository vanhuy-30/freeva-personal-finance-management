import type {
  CalendarBillItem,
  CalendarMonthBounds,
  CalendarRecurringItem,
  CalendarTransactionItem,
} from './calendar';

export const CALENDAR_REPOSITORY = Symbol('CALENDAR_REPOSITORY');

export type CalendarSource = {
  timezone: string;
  today: string;
  transactions: CalendarTransactionItem[];
  /** Active rules with enough fields to project occurrences in the month. */
  recurringRules: Array<{
    id: string;
    type: CalendarRecurringItem['type'];
    amountMinor: bigint;
    currencyCode: string;
    categoryName: string | null;
    unit: 'day' | 'week' | 'month' | 'year';
    interval: number;
    startDate: string;
    endDate: string | null;
    nextExecutionDate: string;
    active: boolean;
  }>;
  bills: CalendarBillItem[];
};

export interface CalendarRepository {
  loadMonth(userId: string, bounds: CalendarMonthBounds, now?: Date): Promise<CalendarSource>;
}
