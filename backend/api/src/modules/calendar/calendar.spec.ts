import 'reflect-metadata';
import { randomUUID } from 'node:crypto';
import { plainToInstance } from 'class-transformer';
import { validateSync } from 'class-validator';
import {
  buildMonth,
  CalendarError,
  dedupeTransferLegs,
  parseMonth,
  type CalendarBillItem,
  type CalendarTransactionItem,
} from './domain/calendar';
import { CalendarQueryDto } from './calendar.dto';

describe('BE-P2-E04 calendar domain', () => {
  it('parses civil month bounds and rejects bad input', () => {
    expect(parseMonth('2026-02')).toEqual({ month: '2026-02', from: '2026-02-01', to: '2026-02-28' });
    expect(parseMonth('2024-02')).toEqual({ month: '2024-02', from: '2024-02-01', to: '2024-02-29' });
    expect(() => parseMonth('2026-13')).toThrow(CalendarError);
    expect(() => parseMonth('2026-2')).toThrow(CalendarError);
    expect(() => parseMonth('2026-02-01')).toThrow(CalendarError);
  });

  it('keeps one leg per transfer group', () => {
    const group = randomUUID();
    const rows: CalendarTransactionItem[] = [
      {
        id: 'b',
        type: 'transfer',
        amountMinor: 100n,
        currencyCode: 'VND',
        categoryName: null,
        transferGroupId: group,
        occurredOn: '2026-10-10',
      },
      {
        id: 'a',
        type: 'transfer',
        amountMinor: -100n,
        currencyCode: 'VND',
        categoryName: null,
        transferGroupId: group,
        occurredOn: '2026-10-10',
      },
      {
        id: 'c',
        type: 'expense',
        amountMinor: -50n,
        currencyCode: 'VND',
        categoryName: 'Coffee',
        transferGroupId: null,
        occurredOn: '2026-10-10',
      },
    ];
    const deduped = dedupeTransferLegs(rows);
    expect(deduped).toHaveLength(2);
    expect(deduped[0]?.id).toBe('a');
    expect(deduped[1]?.id).toBe('c');
  });

  it('builds days with overdue bills from profile today', () => {
    const bill: CalendarBillItem = {
      id: randomUUID(),
      name: 'Điện',
      dueOn: '2026-10-10',
      amountMinor: 350000n,
      amountKind: 'fixed',
      currencyCode: 'VND',
      paidTransactionId: null,
    };
    const month = buildMonth({
      month: '2026-10',
      timezone: 'Asia/Ho_Chi_Minh',
      today: '2026-10-15',
      transactions: [],
      recurring: [],
      bills: [bill],
    });
    expect(month.days).toHaveLength(1);
    expect(month.days[0]?.bills[0]).toMatchObject({ paid: false, overdue: true });
  });

  it('validates month query DTO', () => {
    const ok = plainToInstance(CalendarQueryDto, { month: '2026-10' });
    expect(validateSync(ok)).toHaveLength(0);
    const bad = plainToInstance(CalendarQueryDto, { month: '2026-10-01' });
    expect(validateSync(bad).length).toBeGreaterThan(0);
  });
});
