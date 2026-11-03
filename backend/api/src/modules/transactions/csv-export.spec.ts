import { buildTransactionsCsv, CSV_BOM, csvText, formatMinorAmount, type CsvTransactionRow } from './domain/csv-export';

const row = (over: Partial<CsvTransactionRow> = {}): CsvTransactionRow => ({
  id: '11111111-1111-4111-8111-111111111111', occurredOn: '2026-11-03', occurredTime: '08:30', type: 'expense',
  amountMinor: -12_500_000n, currencyCode: 'VND', minorDigits: 0, walletName: 'Ví chính', categoryName: 'Ăn uống',
  merchant: null, notes: null, tagNames: [], ...over,
});

describe('formatMinorAmount', () => {
  it('formats bigint minor units without locale or float', () => {
    expect(formatMinorAmount(-12_500_000n, 0)).toBe('-12500000');
    expect(formatMinorAmount(-12550n, 2)).toBe('-125.50');
    expect(formatMinorAmount(5n, 2)).toBe('0.05');
    expect(formatMinorAmount(0n, 2)).toBe('0.00');
    expect(formatMinorAmount(9_223_372_036_854_775_807n, 2)).toBe('92233720368547758.07');
  });
});

describe('csvText', () => {
  it('quotes per RFC 4180', () => {
    expect(csvText('a,b')).toBe('"a,b"');
    expect(csvText('nói "xin chào"')).toBe('"nói ""xin chào"""');
    expect(csvText('dòng 1\r\ndòng 2')).toBe('"dòng 1\r\ndòng 2"');
    expect(csvText('Cà phê')).toBe('Cà phê');
    expect(csvText(null)).toBe('');
  });
  it('blocks spreadsheet formulas', () => {
    for (const lead of ['=', '+', '-', '@']) expect(csvText(`${lead}SUM(A1)`)).toBe(`'${lead}SUM(A1)`);
    expect(csvText('=HYPERLINK("x","y")')).toBe('"\'=HYPERLINK(""x"",""y"")"');
  });
});

describe('buildTransactionsCsv', () => {
  it('starts with BOM and header, uses CRLF and keeps negative amounts numeric', () => {
    const csv = buildTransactionsCsv([row({ notes: '=1+1', tagNames: ['a', 'b'] }), row({ amountMinor: 1050n, minorDigits: 2, currencyCode: 'USD', occurredTime: null, type: 'income' })]);
    expect(csv.startsWith(`${CSV_BOM}date,time,type,amount,currency,wallet,category,merchant,notes,tags,transaction_id\r\n`)).toBe(true);
    const lines = csv.trimEnd().split('\r\n');
    expect(lines[1]).toBe("2026-11-03,08:30,expense,-12500000,VND,Ví chính,Ăn uống,,'=1+1,a;b,11111111-1111-4111-8111-111111111111");
    expect(lines[2]).toBe('2026-11-03,,income,10.50,USD,Ví chính,Ăn uống,,,,11111111-1111-4111-8111-111111111111');
    expect(csv.endsWith('\r\n')).toBe(true);
  });
  it('emits only the header for no rows', () => {
    expect(buildTransactionsCsv([])).toBe(`${CSV_BOM}date,time,type,amount,currency,wallet,category,merchant,notes,tags,transaction_id\r\n`);
  });
});
