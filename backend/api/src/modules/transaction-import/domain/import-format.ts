import { CSV_COLUMNS } from '../../transactions/domain/csv-export';

export const IMPORT_FIELDS = ['date', 'time', 'type', 'amount', 'currency', 'wallet', 'category', 'merchant', 'notes', 'id'] as const;
export type ImportField = typeof IMPORT_FIELDS[number];
export const IMPORT_PRESETS = ['freeva', 'money_lover', 'misa', 'custom'] as const;
export type ImportPreset = typeof IMPORT_PRESETS[number];
export type DateFormat = 'iso' | 'dmy' | 'mdy';
/** `plain` = `1234.56`; `dot_thousands` = `1.234,56`; `comma_thousands` = `1,234.56`. */
export type NumberFormat = 'plain' | 'dot_thousands' | 'comma_thousands';

export interface ImportFormat {
  preset: ImportPreset;
  dateFormat: DateFormat;
  numberFormat: NumberFormat;
  /** Header names (any case, accents ignored) accepted for each field, in priority order. */
  aliases: Record<ImportField, string[]>;
}

/** Lower-case, no accents, single spaces: header and name matching never depends on diacritics or casing. */
export const normalizeText = (value: string): string =>
  value.normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/đ/gi, 'd').toLowerCase().replace(/\s+/g, ' ').trim();

const none = (): Record<ImportField, string[]> => ({ date: [], time: [], type: [], amount: [], currency: [], wallet: [], category: [], merchant: [], notes: [], id: [] });

const FREEVA: ImportFormat = {
  preset: 'freeva', dateFormat: 'iso', numberFormat: 'plain',
  aliases: { ...none(), date: ['date'], time: ['time'], type: ['type'], amount: ['amount'], currency: ['currency'], wallet: ['wallet'], category: ['category'], merchant: ['merchant'], notes: ['notes'], id: ['transaction_id'] },
};

// Money Lover and MISA headers are assumptions (no sample file in the repo yet): the alias lists are deliberately broad and
// users can always override a column through `mapping`.
const MONEY_LOVER: ImportFormat = {
  preset: 'money_lover', dateFormat: 'dmy', numberFormat: 'comma_thousands',
  aliases: { ...none(), date: ['date', 'ngay'], amount: ['amount', 'so tien'], currency: ['currency', 'tien te'], wallet: ['wallet', 'account', 'vi'], category: ['category', 'danh muc'], notes: ['note', 'notes', 'ghi chu'], type: ['type', 'loai'] },
};

const MISA: ImportFormat = {
  preset: 'misa', dateFormat: 'dmy', numberFormat: 'dot_thousands',
  aliases: { ...none(), date: ['ngay', 'ngay giao dich', 'date'], amount: ['so tien', 'amount'], currency: ['loai tien', 'tien te', 'currency'], wallet: ['tai khoan', 'vi', 'nguon tien', 'wallet'], category: ['hang muc', 'danh muc', 'category'], notes: ['dien giai', 'ghi chu', 'noi dung', 'notes'], merchant: ['doi tuong', 'nguoi nhan', 'merchant'], type: ['loai', 'loai giao dich', 'type'] },
};

export function formatFor(preset: ImportPreset, overrides: { dateFormat?: DateFormat; numberFormat?: NumberFormat; mapping?: Partial<Record<ImportField, string>> } = {}): ImportFormat {
  const base = { freeva: FREEVA, money_lover: MONEY_LOVER, misa: MISA, custom: { ...FREEVA, preset: 'custom' as const, aliases: none() } }[preset];
  const aliases = { ...base.aliases };
  for (const [field, header] of Object.entries(overrides.mapping ?? {}) as [ImportField, string][]) aliases[field] = [normalizeText(header)];
  return { preset, dateFormat: overrides.dateFormat ?? base.dateFormat, numberFormat: overrides.numberFormat ?? base.numberFormat, aliases };
}

/** Freeva's own export header is exact; anything else needs the caller to pick a preset or mapping. */
export function detectPreset(header: string[]): ImportPreset {
  const names = header.map(normalizeText);
  if (CSV_COLUMNS.every(column => names.includes(column))) return 'freeva';
  if (names.includes('hang muc') || names.includes('dien giai')) return 'misa';
  if (names.includes('category') && names.includes('amount')) return 'money_lover';
  return 'custom';
}

/** Header name → column index per field, plus which headers matched. */
export function resolveColumns(header: string[], format: ImportFormat): Partial<Record<ImportField, number>> {
  const names = header.map(normalizeText);
  const columns: Partial<Record<ImportField, number>> = {};
  for (const field of IMPORT_FIELDS) {
    for (const alias of format.aliases[field]) {
      const index = names.indexOf(normalizeText(alias));
      if (index >= 0) { columns[field] = index; break; }
    }
  }
  return columns;
}
