import { Inject, Injectable } from '@nestjs/common';
import { occurrencesInRange } from '../recurring/domain/calendar';
import {
  buildMonth,
  money,
  parseMonth,
  type CalendarMonth,
  type CalendarRecurringItem,
} from './domain/calendar';
import { CALENDAR_REPOSITORY, type CalendarRepository } from './domain/calendar.repository';

function response(month: CalendarMonth) {
  return {
    month: month.month,
    timezone: month.timezone,
    today: month.today,
    days: month.days.map(day => ({
      date: day.date,
      transactions: day.transactions.map(item => ({
        id: item.id,
        type: item.type,
        amountMinor: money(item.amountMinor),
        currencyCode: item.currencyCode,
        categoryName: item.categoryName,
      })),
      recurring: day.recurring.map(item => ({
        id: item.id,
        type: item.type,
        amountMinor: money(item.amountMinor),
        currencyCode: item.currencyCode,
        categoryName: item.categoryName,
        occurredOn: item.occurredOn,
      })),
      bills: day.bills.map(item => ({
        id: item.id,
        name: item.name,
        dueOn: item.dueOn,
        amountMinor: money(item.amountMinor),
        amountKind: item.amountKind,
        currencyCode: item.currencyCode,
        paid: item.paid,
        overdue: item.overdue,
      })),
    })),
  };
}

@Injectable()
export class CalendarService {
  constructor(@Inject(CALENDAR_REPOSITORY) private readonly repository: CalendarRepository) {}

  async month(userId: string, month: string, now = new Date()) {
    const bounds = parseMonth(month);
    const source = await this.repository.loadMonth(userId, bounds, now);
    const recurring: CalendarRecurringItem[] = [];
    for (const rule of source.recurringRules) {
      for (const occurredOn of occurrencesInRange({
        nextExecutionDate: rule.nextExecutionDate,
        startDate: rule.startDate,
        endDate: rule.endDate,
        rangeFrom: bounds.from,
        rangeTo: bounds.to,
        unit: rule.unit,
        interval: rule.interval,
        active: rule.active,
      })) {
        recurring.push({
          id: rule.id,
          type: rule.type,
          amountMinor: rule.amountMinor,
          currencyCode: rule.currencyCode,
          categoryName: rule.categoryName,
          occurredOn,
        });
      }
    }
    return response(buildMonth({
      month: bounds.month,
      timezone: source.timezone,
      today: source.today,
      transactions: source.transactions,
      recurring,
      bills: source.bills,
    }));
  }
}
