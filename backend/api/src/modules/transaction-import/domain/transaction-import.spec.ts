import { buildTransactionsCsv } from '../../transactions/domain/csv-export';
import { CsvParseError, detectDelimiter, parseCsv } from './csv-parse';
import { detectPreset, formatFor } from './import-format';
import {
  cleanCell, decimalToMinor, deterministicUuid, parseDate, parseDecimalText, parseRows, planRows,
  type ExistingTransaction, type ImportAccount, type ImportCategory, type ImportMaps,
} from './transaction-import';

const vnd: ImportAccount = { id: 'a1', name: 'Tiền mặt', currencyCode: 'VND', minorDigits: 0 };
const bank: ImportAccount = { id: 'a2', name: 'Ngân hàng', currencyCode: 'VND', minorDigits: 0 };
const usd: ImportAccount = { id: 'a3', name: 'Dollar', currencyCode: 'USD', minorDigits: 2 };
const food: ImportCategory = { id: 'c1', name: 'Ăn uống', kind: 'expense' };
const salary: ImportCategory = { id: 'c2', name: 'Lương', kind: 'income' };
const maps: ImportMaps = { walletMap: {}, categoryMap: {}, defaultAccountId: null };
const run = (csv: string, preset: Parameters<typeof formatFor>[0], existing: ExistingTransaction[] = [], extra: Partial<ImportMaps> = {}, accounts = [vnd, bank, usd]) =>
  planRows(parseRows(parseCsv(csv), formatFor(preset)).rows, { ...maps, ...extra }, accounts, [food, salary], existing);

describe('csv parse', () => {
  it('reads quotes, doubled quotes, embedded newlines, CRLF and BOM', () => {
    expect(parseCsv('﻿a,b\r\n"x,1","say ""hi""\nthere"\r\n\r\nlast,')).toEqual([['a', 'b'], ['x,1', 'say "hi"\nthere'], ['last', '']]);
  });
  it('rejects an unterminated quote and detects semicolons', () => {
    expect(() => parseCsv('a,"b')).toThrow(CsvParseError);
    expect(detectDelimiter('a;b;c,d\n1;2;3')).toBe(';');
  });
  it('unwraps the formula guard the export adds', () => {
    expect(cleanCell("'=SUM(A1)")).toBe('=SUM(A1)');
    expect(cleanCell("'quoted")).toBe("'quoted");
  });
});

describe('amounts and dates', () => {
  it('parses number formats without floats', () => {
    expect(decimalToMinor(parseDecimalText('-125.50', 'plain')!, 2)).toBe(-12550n);
    expect(decimalToMinor(parseDecimalText('1.234.567', 'dot_thousands')!, 0)).toBe(1234567n);
    expect(decimalToMinor(parseDecimalText('1,234.5 ₫', 'comma_thousands')!, 2)).toBe(123450n);
    expect(decimalToMinor(parseDecimalText('(2.000)', 'dot_thousands')!, 0)).toBe(-2000n);
    expect(decimalToMinor(parseDecimalText('9007199254740993', 'plain')!, 0)).toBe(9007199254740993n);
  });
  it('rejects garbage and too many decimals', () => {
    expect(parseDecimalText('12a', 'plain')).toBeNull();
    expect(parseDecimalText('1,2', 'plain')).toBeNull();
    expect(decimalToMinor(parseDecimalText('10.005', 'plain')!, 2)).toBeNull();
    expect(decimalToMinor(parseDecimalText('10.500', 'plain')!, 2)).toBe(1050n);
  });
  it('parses iso, dmy and mdy with optional time and rejects impossible days', () => {
    expect(parseDate('2026-11-03', 'iso')).toEqual({ date: '2026-11-03', time: null });
    expect(parseDate('3/11/2026 08:05', 'dmy')).toEqual({ date: '2026-11-03', time: '08:05' });
    expect(parseDate('11/03/2026', 'mdy').date).toBe('2026-11-03');
    expect(parseDate('31/02/2026', 'dmy').date).toBeNull();
  });
  it('derives a stable uuid', () => {
    expect(deterministicUuid('b', 1, 0)).toBe(deterministicUuid('b', 1, 0));
    expect(deterministicUuid('b', 1, 0)).not.toBe(deterministicUuid('b', 1, 1));
    expect(deterministicUuid('b', 1, 0)).toMatch(/^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/);
  });
});

describe('plan rows', () => {
  const header = 'date,time,type,amount,currency,wallet,category,merchant,notes,tags,transaction_id\r\n';
  it('re-imports the BE-P3-010 export, pairing the two transfer rows', () => {
    const csv = buildTransactionsCsv([
      { id: 'i1', occurredOn: '2026-11-01', occurredTime: '08:30', type: 'expense', amountMinor: -45000n, currencyCode: 'VND', minorDigits: 0, walletName: 'Tiền mặt', categoryName: 'Ăn uống', merchant: '=cafe', notes: null, tagNames: [] },
      { id: 'i2', occurredOn: '2026-11-02', occurredTime: null, type: 'transfer', amountMinor: -100000n, currencyCode: 'VND', minorDigits: 0, walletName: 'Tiền mặt', categoryName: null, merchant: null, notes: 'rút', tagNames: [] },
      { id: 'i3', occurredOn: '2026-11-02', occurredTime: null, type: 'transfer', amountMinor: 100000n, currencyCode: 'VND', minorDigits: 0, walletName: 'Ngân hàng', categoryName: null, merchant: null, notes: 'rút', tagNames: [] },
    ]);
    const rows = run(csv, 'freeva');
    expect(rows.map(row => row.status)).toEqual(['ready', 'ready']);
    expect(rows[0]).toMatchObject({ type: 'expense', occurredTime: '08:30', merchant: '=cafe', categoryId: 'c1', legs: [{ accountId: 'a1', amountMinor: -45000n }] });
    expect(rows[1]).toMatchObject({ type: 'transfer', rows: [2, 3], legs: [{ accountId: 'a1', amountMinor: -100000n }, { accountId: 'a2', amountMinor: 100000n }] });
  });
  it('reports each problem on its own row', () => {
    const rows = run(`${header}2026-13-01,,expense,100,VND,Tiền mặt,Ăn uống,,,,\r\n2026-11-01,,expense,abc,VND,Tiền mặt,Ăn uống,,,,\r\n2026-11-01,,adjustment,100,VND,Tiền mặt,,,,,\r\n2026-11-01,,expense,100,VND,Ví lạ,Ăn uống,,,,\r\n2026-11-01,,expense,100,USD,Tiền mặt,Ăn uống,,,,\r\n2026-11-01,,expense,100,VND,Tiền mặt,Lạ,,,,\r\n2026-11-01,,expense,100,VND,Tiền mặt,Lương,,,,\r\n2026-11-01,,transfer,-100,VND,Tiền mặt,,,,,\r\n`, 'freeva');
    expect(rows.map(row => row.errors[0])).toEqual(['DATE_INVALID', 'AMOUNT_INVALID', 'TYPE_UNSUPPORTED', 'WALLET_UNMAPPED', 'CURRENCY_MISMATCH', 'CATEGORY_UNMAPPED', 'CATEGORY_KIND_MISMATCH', 'TRANSFER_UNPAIRED']);
    expect(rows.every(row => row.status === 'invalid')).toBe(true);
  });
  it('maps wallets and categories through the supplied maps and a default wallet', () => {
    const rows = run('Ngày,Số tiền,Hạng mục,Diễn giải\r\n03/11/2026,"1.500.000",Thu nhập khác,Thưởng\r\n', 'misa', [], { walletMap: {}, categoryMap: { 'thu nhap khac': 'c2' }, defaultAccountId: 'a2' });
    expect(rows[0]).toMatchObject({ status: 'ready', type: 'income', categoryId: 'c2', legs: [{ accountId: 'a2', amountMinor: 1500000n }], notes: 'Thưởng' });
  });
  it('takes the type from the sign when the file has no type column', () => {
    const rows = run('Date,Category,Amount,Note,Wallet\r\n03/11/2026,Ăn uống,"-45,000",pho,Tiền mặt\r\n', 'money_lover');
    expect(rows[0]).toMatchObject({ type: 'expense', legs: [{ amountMinor: -45000n }] });
  });
  it('flags duplicates of existing rows once each and never matches a different amount', () => {
    const existing = [{ id: 'e1', accountId: 'a1', occurredOn: '2026-11-01', amountMinor: -45000n, type: 'expense', merchant: null, notes: 'Pho' }];
    const csv = `${header}2026-11-01,,expense,-45000,VND,Tiền mặt,Ăn uống,,pho,,\r\n2026-11-01,,expense,-45000,VND,Tiền mặt,Ăn uống,,pho,,\r\n2026-11-01,,expense,-46000,VND,Tiền mặt,Ăn uống,,pho,,\r\n`;
    const rows = run(csv, 'freeva', existing);
    expect(rows.map(row => row.status)).toEqual(['duplicate', 'ready', 'ready']);
    expect(rows[0].duplicateOf).toBe('e1');
    expect(run(`${header}2026-11-09,,expense,-1,VND,Ví lạ,Ăn uống,,,,e1\r\n`, 'freeva', existing, { walletMap: { 'ví lạ': 'a1' } })[0].status).toBe('duplicate');
  });
  it('fails a file without a date or amount column', () => {
    expect(() => parseRows(parseCsv('foo,bar\r\n1,2\r\n'), formatFor('custom'))).toThrow();
    expect(detectPreset(['date', 'time', 'type', 'amount', 'currency', 'wallet', 'category', 'merchant', 'notes', 'tags', 'transaction_id'])).toBe('freeva');
  });
});

describe('BE-P5-E03 categories for rows the file left empty', () => {
  const csv = 'date,time,type,amount,currency,wallet,category,merchant,notes,tags,transaction_id\n2026-11-03,,expense,-45000,VND,Tiền mặt,,Highlands,,,\n2026-11-03,,expense,-62000,VND,Tiền mặt,Ăn uống,Grab,,,\n2026-11-04,,income,100000,VND,Tiền mặt,,Thưởng,,,\n';
  it('uses the picked category only when the file category is empty, and checks kind and ownership', () => {
    const rows = run(csv, 'freeva', [], { rowCategory: new Map([[1, 'c1'], [2, 'c1'], [3, 'c2']]) });
    expect(rows.map(r => [r.status, r.categoryId, r.errors])).toEqual([['ready', 'c1', []], ['ready', 'c1', []], ['ready', 'c2', []]]);
    expect(run(csv, 'freeva', [], { rowCategory: new Map([[3, 'c1']]) })[2].errors).toEqual(['CATEGORY_KIND_MISMATCH']);
    expect(run(csv, 'freeva', [], { rowCategory: new Map([[1, 'other']]) })[0].errors).toEqual(['CATEGORY_UNMAPPED']);
  });
  it('keeps the old behaviour without a pick: empty expense category is unmapped, income may stay empty', () => {
    const rows = run(csv, 'freeva');
    expect(rows.map(r => [r.status, r.categoryId])).toEqual([['invalid', null], ['ready', 'c1'], ['ready', null]]);
  });
});
