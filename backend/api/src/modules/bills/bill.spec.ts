import 'reflect-metadata';
import { randomUUID } from 'node:crypto';
import { plainToInstance } from 'class-transformer';
import { validateSync } from 'class-validator';
import {
  billFlags,
  BillError,
  normalizeName,
  positiveMinor,
  validateBillInput,
  type BillInput,
} from './domain/bill';
import { CreateBillDto, PayBillDto } from './bill.dto';

const day = (value: string) => new Date(`${value}T00:00:00.000Z`);

function base(patch: Partial<BillInput> = {}): BillInput {
  return {
    clientId: randomUUID(),
    name: 'Điện',
    dueOn: day('2026-10-15'),
    amountMinor: 350000n,
    amountKind: 'fixed',
    currencyCode: 'VND',
    recurringRuleId: null,
    ...patch,
  };
}

describe('BE-P2-E03 bill domain', () => {
  it('accepts one-off and estimated bills with positive minor units', () => {
    expect(() => validateBillInput(base())).not.toThrow();
    expect(() => validateBillInput(base({ amountKind: 'estimated', amountMinor: 1n }))).not.toThrow();
    expect(normalizeName('  Nước  ')).toBe('Nước');
    expect(positiveMinor('120000')).toBe(120000n);
  });

  it('rejects zero/negative amounts and empty names', () => {
    expect(() => validateBillInput(base({ amountMinor: 0n }))).toThrow(BillError);
    expect(() => positiveMinor('0')).toThrow(BillError);
    expect(() => positiveMinor('-1')).toThrow(BillError);
    expect(() => normalizeName('')).toThrow(BillError);
    expect(() => normalizeName('x'.repeat(81))).toThrow(BillError);
  });

  it('derives overdue only when unpaid and due before today', () => {
    const unpaid = { dueOn: day('2026-10-14'), paidTransactionId: null };
    expect(billFlags(unpaid, '2026-10-15')).toEqual({ paid: false, overdue: true, status: 'overdue' });
    expect(billFlags(unpaid, '2026-10-14')).toEqual({ paid: false, overdue: false, status: 'open' });
    expect(billFlags({ dueOn: day('2026-10-01'), paidTransactionId: randomUUID() }, '2026-10-15')).toEqual({
      paid: true, overdue: false, status: 'paid',
    });
  });

  it('does not invent a transaction when marking overdue', () => {
    const flags = billFlags({ dueOn: day('2020-01-01'), paidTransactionId: null }, '2026-10-15');
    expect(flags.overdue).toBe(true);
    expect(flags.paid).toBe(false);
  });

  it('validates create and pay DTO shapes', () => {
    const ok = plainToInstance(CreateBillDto, {
      clientId: randomUUID(),
      name: 'Internet',
      dueOn: '2026-11-01',
      amountMinor: '199000',
      amountKind: 'fixed',
      currencyCode: 'vnd',
    });
    expect(validateSync(ok)).toHaveLength(0);
    expect(ok.currencyCode).toBe('VND');

    const bad = plainToInstance(CreateBillDto, {
      clientId: randomUUID(),
      name: 'Internet',
      dueOn: '2026-11-01',
      amountMinor: '-199000',
      amountKind: 'fixed',
      currencyCode: 'VND',
    });
    expect(validateSync(bad).length).toBeGreaterThan(0);

    const pay = plainToInstance(PayBillDto, {
      version: 1,
      transactionId: randomUUID(),
    });
    expect(validateSync(pay)).toHaveLength(0);
  });
});
