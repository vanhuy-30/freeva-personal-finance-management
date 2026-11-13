import { createHash } from 'node:crypto';
import { categoryKindFits, OCCURRED_TIME } from '../../transactions/domain/transaction';
import { resolveColumns, normalizeText, type ImportField, type ImportFormat, type NumberFormat } from './import-format';

/** One request commits in a single database transaction, so the file size is bounded (the export cap of 50 000 would not fit). */
export const IMPORT_MAX_ROWS = 2_000;

export class TransactionImportError extends Error {
  constructor(readonly code: 'VALIDATION_ERROR' | 'IMPORT_NOT_FOUND' | 'IMPORT_CONFLICT' | 'FILE_INVALID' | 'FILE_TOO_LARGE') { super(code); }
}

export type RowError =
  | 'DATE_INVALID' | 'AMOUNT_INVALID' | 'TYPE_UNSUPPORTED' | 'WALLET_UNMAPPED' | 'WALLET_AMBIGUOUS' | 'CATEGORY_UNMAPPED'
  | 'CATEGORY_AMBIGUOUS' | 'CATEGORY_KIND_MISMATCH' | 'CURRENCY_MISMATCH' | 'TRANSFER_UNPAIRED' | 'TRANSFER_SAME_WALLET'
  | 'TRANSACTION_CONFLICT' | 'VALIDATION_ERROR' | 'ACCOUNT_NOT_FOUND';
export type RowStatus = 'ready' | 'duplicate' | 'invalid';
export type ImportType = 'income' | 'expense' | 'transfer';

export interface ImportAccount { id: string; name: string; currencyCode: string; minorDigits: number }
export interface ImportCategory { id: string; name: string; kind: 'expense' | 'income' | 'both' }
export interface ExistingTransaction { id: string; accountId: string; occurredOn: string; amountMinor: bigint; type: string; merchant: string | null; notes: string | null }
export interface ImportMaps {
  /** Source wallet name → Freeva account id. Keys are matched ignoring case and accents. */
  walletMap: Record<string, string>;
  /** Source category name → Freeva category id; `null` = deliberately no category (income only). */
  categoryMap: Record<string, string | null>;
  defaultAccountId: string | null;
  /**
   * BE-P5-E03: category for rows whose file category is empty, by row number — what the user picked in
   * the sheet, else the suggestion. Checked against the user's categories like any mapped category.
   */
  rowCategory?: Map<number, string>;
}

export interface ParsedRow {
  row: number;
  date: string | null;
  time: string | null;
  typeText: string;
  amount: DecimalText | null;
  currency: string;
  wallet: string;
  category: string;
  merchant: string;
  notes: string;
  sourceId: string;
}

export interface PlannedLeg { accountId: string; currencyCode: string; amountMinor: bigint }
export interface PlannedRow {
  /** 1-based data rows of the file this row came from (a transfer uses two). */
  rows: number[];
  status: RowStatus;
  errors: RowError[];
  type: ImportType | null;
  occurredOn: string | null;
  occurredTime: string | null;
  legs: PlannedLeg[];
  categoryId: string | null;
  merchant: string | null;
  notes: string | null;
  duplicateOf: string | null;
}

export interface DecimalText { negative: boolean; whole: string; fraction: string }

/** Unwraps the `'` the export adds in front of `= + - @` so a Freeva file re-imports to the original text. */
export const cleanCell = (value: string | undefined): string => {
  const text = (value ?? '').trim();
  return /^'[=+\-@\t\r]/.test(text) ? text.slice(1) : text;
};

const PATTERNS: Record<NumberFormat, { group: RegExp; decimal: string; strip: RegExp }> = {
  plain: { group: /^\d+(\.\d+)?$/, decimal: '.', strip: /^$/ },
  dot_thousands: { group: /^(\d{1,3}(\.\d{3})+|\d+)(,\d+)?$/, decimal: ',', strip: /\./g },
  comma_thousands: { group: /^(\d{1,3}(,\d{3})+|\d+)(\.\d+)?$/, decimal: '.', strip: /,/g },
};

/** Text → sign/whole/fraction digits. Currency symbols, spaces and `(1.000)` negatives are tolerated; anything else is null. */
export function parseDecimalText(input: string, format: NumberFormat): DecimalText | null {
  let text = input.replace(/[\s\u00a0]/g, '').replace(/₫|đ|vnd|vnđ|usd|\$|€|£/gi, '');
  let negative = false;
  if (/^\(.*\)$/.test(text)) { negative = true; text = text.slice(1, -1); }
  if (text.startsWith('-')) { negative = !negative; text = text.slice(1); } else if (text.startsWith('+')) text = text.slice(1);
  const rule = PATTERNS[format];
  if (!rule.group.test(text)) return null;
  const [whole, fraction = ''] = text.replace(rule.strip, '').split(rule.decimal);
  return { negative, whole: whole.replace(/^0+(?=\d)/, ''), fraction };
}

/** Exact bigint minor units; null when the value has more non-zero decimals than the currency allows. */
export function decimalToMinor(value: DecimalText, minorDigits: number): bigint | null {
  const extra = value.fraction.slice(minorDigits);
  if (/[^0]/.test(extra)) return null;
  const minor = BigInt(`${value.whole}${value.fraction.slice(0, minorDigits).padEnd(minorDigits, '0')}`);
  return value.negative ? -minor : minor;
}

function calendar(year: number, month: number, day: number): string | null {
  const date = new Date(Date.UTC(year, month - 1, day));
  if (year < 1 || date.getUTCFullYear() !== year || date.getUTCMonth() !== month - 1 || date.getUTCDate() !== day) return null;
  return date.toISOString().slice(0, 10);
}

/** Calendar day (and an optional trailing clock) from the file's date format; time is returned as HH:mm. */
export function parseDate(input: string, format: ImportFormat['dateFormat']): { date: string | null; time: string | null } {
  const [datePart, timePart] = input.trim().split(/[T\s]+/, 2);
  const time = timePart && /^\d{1,2}:\d{2}/.test(timePart) ? timePart.slice(0, 5).padStart(5, '0') : null;
  const clock = time && OCCURRED_TIME.test(time) ? time : null;
  if (format === 'iso') {
    const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(datePart ?? '');
    return { date: match ? calendar(+match[1], +match[2], +match[3]) : null, time: clock };
  }
  const match = /^(\d{1,2})[/.-](\d{1,2})[/.-](\d{4})$/.exec(datePart ?? '');
  if (!match) return { date: null, time: clock };
  const [first, second] = [+match[1], +match[2]];
  return { date: format === 'dmy' ? calendar(+match[3], second, first) : calendar(+match[3], first, second), time: clock };
}

const INCOME = new Set(['income', 'thu', 'thu nhap', 'khoan thu']);
const EXPENSE = new Set(['expense', 'chi', 'chi tieu', 'khoan chi']);
const TRANSFER = new Set(['transfer', 'chuyen khoan', 'chuyen tien']);

export function typeOf(text: string, amount: DecimalText | null): ImportType | 'unsupported' | null {
  const key = normalizeText(text);
  if (!key) return amount ? (amount.negative ? 'expense' : 'income') : null;
  if (INCOME.has(key)) return 'income';
  if (EXPENSE.has(key)) return 'expense';
  if (TRANSFER.has(key)) return 'transfer';
  return 'unsupported';
}

/** Header + data rows → typed cells. Throws FILE_INVALID when no amount/date column can be found. */
/** `maxRows` is app config `import.maxRows` (BE-P5-001), never above IMPORT_MAX_ROWS. */
export function parseRows(
  table: string[][],
  format: ImportFormat,
  maxRows = IMPORT_MAX_ROWS,
): { rows: ParsedRow[]; columns: Partial<Record<ImportField, number>> } {
  if (table.length < 2) throw new TransactionImportError('FILE_INVALID');
  const columns = resolveColumns(table[0], format);
  if (columns.date === undefined || columns.amount === undefined) throw new TransactionImportError('FILE_INVALID');
  if (table.length - 1 > Math.min(maxRows, IMPORT_MAX_ROWS)) throw new TransactionImportError('FILE_TOO_LARGE');
  const cell = (line: string[], field: ImportField) => (columns[field] === undefined ? '' : cleanCell(line[columns[field]!]));
  const rows = table.slice(1).map((line, index): ParsedRow => {
    const when = parseDate(cell(line, 'date'), format.dateFormat);
    return {
      row: index + 1, date: when.date, time: cell(line, 'time') ? parseDate(`2000-01-01 ${cell(line, 'time')}`, 'iso').time : when.time,
      typeText: cell(line, 'type'), amount: parseDecimalText(cell(line, 'amount'), format.numberFormat),
      currency: cell(line, 'currency').toUpperCase(), wallet: cell(line, 'wallet'), category: cell(line, 'category'),
      merchant: cell(line, 'merchant'), notes: cell(line, 'notes'), sourceId: cell(line, 'id'),
    };
  });
  return { rows, columns };
}

const same = (a: string, b: string) => normalizeText(a) === normalizeText(b);
const keyOf = (name: string) => normalizeText(name);
const lookup = <T>(map: Record<string, T>, name: string): { found: boolean; value: T | undefined } => {
  const key = Object.keys(map).find(item => keyOf(item) === keyOf(name));
  return key === undefined ? { found: false, value: undefined } : { found: true, value: map[key] };
};

function resolveAccount(name: string, maps: ImportMaps, accounts: ImportAccount[]): ImportAccount | RowError {
  const mapped = lookup(maps.walletMap, name);
  if (mapped.found) return accounts.find(account => account.id === mapped.value) ?? 'WALLET_UNMAPPED';
  const matches = accounts.filter(account => same(account.name, name));
  if (matches.length === 1 && name) return matches[0];
  if (matches.length > 1) return 'WALLET_AMBIGUOUS';
  if (!name && maps.defaultAccountId) return accounts.find(account => account.id === maps.defaultAccountId) ?? 'WALLET_UNMAPPED';
  return 'WALLET_UNMAPPED';
}

function resolveCategory(row: number, name: string, type: 'income' | 'expense', maps: ImportMaps, categories: ImportCategory[]): { id: string | null } | RowError {
  const picked = name.trim() ? undefined : maps.rowCategory?.get(row);
  if (picked !== undefined) {
    const category = categories.find(item => item.id === picked);
    if (!category) return 'CATEGORY_UNMAPPED';
    return categoryKindFits(type, category.kind) ? { id: category.id } : 'CATEGORY_KIND_MISMATCH';
  }
  const mapped = lookup(maps.categoryMap, name);
  if (mapped.found) {
    if (mapped.value === null) return type === 'income' ? { id: null } : 'CATEGORY_UNMAPPED';
    const category = categories.find(item => item.id === mapped.value);
    if (!category) return 'CATEGORY_UNMAPPED';
    return categoryKindFits(type, category.kind) ? { id: category.id } : 'CATEGORY_KIND_MISMATCH';
  }
  if (!name) return type === 'income' ? { id: null } : 'CATEGORY_UNMAPPED';
  const named = categories.filter(item => same(item.name, name));
  if (!named.length) return 'CATEGORY_UNMAPPED';
  const fitting = named.filter(item => categoryKindFits(type, item.kind));
  if (fitting.length === 1) return { id: fitting[0].id };
  return fitting.length ? 'CATEGORY_AMBIGUOUS' : 'CATEGORY_KIND_MISMATCH';
}

const invalid = (rows: number[], errors: RowError[], base: Partial<PlannedRow> = {}): PlannedRow => ({
  rows, status: 'invalid', errors, type: null, occurredOn: null, occurredTime: null, legs: [], categoryId: null, merchant: null, notes: null, duplicateOf: null, ...base,
});

interface Resolved { parsed: ParsedRow; type: ImportType; account: ImportAccount; amountMinor: bigint }

/**
 * Turns parsed cells into planned transactions: types, wallets, categories, minor units, transfer pairs and duplicate flags.
 * Pure: the caller supplies the user's accounts, categories and existing transactions. Never creates wallets or categories.
 */
export function planRows(parsed: ParsedRow[], maps: ImportMaps, accounts: ImportAccount[], categories: ImportCategory[], existing: ExistingTransaction[]): PlannedRow[] {
  const planned: PlannedRow[] = [];
  const transfers: Resolved[] = [];
  for (const row of parsed) {
    const errors: RowError[] = [];
    const type = typeOf(row.typeText, row.amount);
    if (row.date === null) errors.push('DATE_INVALID');
    if (row.amount === null) errors.push('AMOUNT_INVALID');
    if (type === 'unsupported') errors.push('TYPE_UNSUPPORTED');
    const account = resolveAccount(row.wallet, maps, accounts);
    if (typeof account === 'string') errors.push(account);
    if (errors.length) { planned.push(invalid([row.row], errors, { occurredOn: row.date })); continue; }
    const wallet = account as ImportAccount;
    const amount = decimalToMinor(row.amount!, wallet.minorDigits);
    if (amount === null || amount === 0n) { planned.push(invalid([row.row], ['AMOUNT_INVALID'], { occurredOn: row.date })); continue; }
    if (row.currency && row.currency !== wallet.currencyCode) { planned.push(invalid([row.row], ['CURRENCY_MISMATCH'], { occurredOn: row.date })); continue; }
    const resolved: Resolved = { parsed: row, type: type as ImportType, account: wallet, amountMinor: amount };
    if (resolved.type === 'transfer') { transfers.push(resolved); continue; }
    const category = resolveCategory(row.row, row.category, resolved.type, maps, categories);
    if (typeof category === 'string') { planned.push(invalid([row.row], [category], { occurredOn: row.date })); continue; }
    const magnitude = amount < 0n ? -amount : amount;
    planned.push({
      rows: [row.row], status: 'ready', errors: [], type: resolved.type, occurredOn: row.date, occurredTime: row.time,
      legs: [{ accountId: wallet.id, currencyCode: wallet.currencyCode, amountMinor: resolved.type === 'income' ? magnitude : -magnitude }],
      categoryId: category.id, merchant: row.merchant ? row.merchant.slice(0, 200) : null, notes: row.notes || null, duplicateOf: null,
    });
  }
  planned.push(...pairTransfers(transfers));
  planned.sort((a, b) => a.rows[0] - b.rows[0]);
  markDuplicates(planned, parsed, existing);
  return planned;
}

/** Opposite-signed transfer rows with the same day, time, size and currency become one two-leg transfer; leftovers are invalid. */
function pairTransfers(rows: Resolved[]): PlannedRow[] {
  const out: PlannedRow[] = [];
  const open = new Map<string, Resolved[]>();
  for (const item of rows) {
    const magnitude = item.amountMinor < 0n ? -item.amountMinor : item.amountMinor;
    const key = `${item.parsed.date}|${item.parsed.time ?? ''}|${magnitude}|${item.account.currencyCode}`;
    const waiting = open.get(key) ?? [];
    const matchIndex = waiting.findIndex(other => (other.amountMinor < 0n) !== (item.amountMinor < 0n));
    if (matchIndex < 0) { open.set(key, [...waiting, item]); continue; }
    const [other] = waiting.splice(matchIndex, 1);
    open.set(key, waiting);
    const [source, destination] = item.amountMinor < 0n ? [item, other] : [other, item];
    const rowsUsed = [source.parsed.row, destination.parsed.row].sort((a, b) => a - b);
    if (source.account.id === destination.account.id) { out.push(invalid(rowsUsed, ['TRANSFER_SAME_WALLET'], { occurredOn: item.parsed.date })); continue; }
    out.push({
      rows: rowsUsed, status: 'ready', errors: [], type: 'transfer', occurredOn: item.parsed.date, occurredTime: item.parsed.time,
      legs: [source, destination].map(leg => ({ accountId: leg.account.id, currencyCode: leg.account.currencyCode, amountMinor: leg.amountMinor })),
      categoryId: null, merchant: null, notes: source.parsed.notes || destination.parsed.notes || null, duplicateOf: null,
    });
  }
  for (const waiting of open.values()) {
    for (const item of waiting) out.push(invalid([item.parsed.row], ['TRANSFER_UNPAIRED'], { occurredOn: item.parsed.date }));
  }
  return out;
}

/**
 * A row is a duplicate of an existing transaction when wallet, day, signed amount, type and normalized merchant/notes all match,
 * or when its `transaction_id` is an existing id. Each existing transaction matches at most one row, so two identical coffees in
 * the file are only both flagged when two already exist.
 */
function markDuplicates(planned: PlannedRow[], parsed: ParsedRow[], existing: ExistingTransaction[]): void {
  const byId = new Map(existing.map(item => [item.id, item]));
  const used = new Set<string>();
  const sourceIds = new Map(parsed.map(item => [item.row, item.sourceId]));
  for (const row of planned) {
    if (row.status !== 'ready') continue;
    const byFileId = row.rows.map(index => sourceIds.get(index)).find(id => id && byId.has(id) && !used.has(id));
    const first = row.legs[0];
    const text = normalizeText(`${row.merchant ?? ''} ${row.notes ?? ''}`);
    const match = byFileId ? byId.get(byFileId) : existing.find(item => !used.has(item.id) && item.type === row.type && item.accountId === first.accountId &&
      item.occurredOn === row.occurredOn && item.amountMinor === first.amountMinor && normalizeText(`${item.merchant ?? ''} ${item.notes ?? ''}`) === text);
    if (!match) continue;
    used.add(match.id);
    row.status = 'duplicate';
    row.duplicateOf = match.id;
  }
}

/** Stable UUID (v5 layout) so retrying a commit replays the same transaction clientIds instead of creating new ones. */
export function deterministicUuid(...parts: Array<string | number>): string {
  const hash = createHash('sha1').update(parts.join(':')).digest();
  hash[6] = (hash[6] & 0x0f) | 0x50;
  hash[8] = (hash[8] & 0x3f) | 0x80;
  const hex = hash.subarray(0, 16).toString('hex');
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}
