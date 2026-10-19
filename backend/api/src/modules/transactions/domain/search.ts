const INT64_MAX = 9223372036854775807n;
const GROUPS: ReadonlyArray<readonly [string, string]> = [
  ['aàáảãạăằắẳẵặâầấẩẫậAÀÁẢÃẠĂẰẮẲẴẶÂẦẤẨẪẬ', 'a'],
  ['eèéẻẽẹêềếểễệEÈÉẺẼẸÊỀẾỂỄỆ', 'e'],
  ['iìíỉĩịIÌÍỈĨỊ', 'i'],
  ['oòóỏõọôồốổỗộơờớởỡợOÒÓỎÕỌÔỒỐỔỖỘƠỜỚỞỠỢ', 'o'],
  ['uùúủũụưừứửữựUÙÚỦŨỤƯỪỨỬỮỰ', 'u'],
  ['yỳýỷỹỵYỲÝỶỸỴ', 'y'],
  ['dđDĐ', 'd'],
  ['BCFGHJKLMNPQRSTVWXZ', 'bcfghjklmnpqrstvwxz'],
];

function foldTable() {
  let from = '';
  let to = '';
  const seen = new Set<string>();
  for (const [sources, targets] of GROUPS) {
    const sourceChars = [...sources];
    const targetChars = [...targets];
    const mapped = targetChars.length === 1 ? sourceChars.map(() => targetChars[0]) : targetChars;
    if (sourceChars.length !== mapped.length) throw new Error('Vietnamese fold table is unbalanced');
    for (let index = 0; index < sourceChars.length; index++) {
      const source = sourceChars[index];
      if (seen.has(source)) throw new Error('Vietnamese fold table has a duplicate');
      seen.add(source);
      from += source;
      to += mapped[index];
    }
  }
  return { from, to };
}

const table = foldTable();
export const VIETNAMESE_FOLD_FROM = table.from;
export const VIETNAMESE_FOLD_TO = table.to;
const foldMap = new Map([...VIETNAMESE_FOLD_FROM].map((char, index) => [char, [...VIETNAMESE_FOLD_TO][index]]));

export function foldVietnamese(value: string): string {
  let folded = '';
  for (const char of value.normalize('NFC')) folded += foldMap.get(char) ?? char;
  return folded;
}

export function escapeLike(value: string): string {
  return value.replace(/[\\%_]/g, char => `\\${char}`);
}

export interface MinorAmountSearch { kind: 'minor'; minor: bigint }
export interface MajorAmountSearch { kind: 'major'; whole: bigint; fraction: bigint; fractionDigits: number }
export type AmountSearch = MinorAmountSearch | MajorAmountSearch;
export interface ParsedTransactionSearch { like: string; amount: AmountSearch | null }

export function parseTransactionSearch(raw: string | undefined): ParsedTransactionSearch | null {
  const trimmed = raw?.trim();
  if (!trimmed) return null;
  return { like: `%${escapeLike(foldVietnamese(trimmed))}%`, amount: parseAmount(trimmed.replace(/ /g, '')) };
}

function parseAmount(compact: string): AmountSearch | null {
  if (/^\d+$/.test(compact)) return minorAmount(BigInt(compact));
  if (/^\d{1,3}([.,]\d{3})+$/.test(compact)) return minorAmount(BigInt(compact.replace(/[.,]/g, '')));
  const decimal = /^(\d+)[.,](\d+)$/.exec(compact);
  if (!decimal || decimal[2].length === 3) return null;
  return { kind: 'major', whole: BigInt(decimal[1]), fraction: BigInt(decimal[2]), fractionDigits: decimal[2].length };
}

function minorAmount(minor: bigint): AmountSearch | null {
  return minor <= INT64_MAX ? { kind: 'minor', minor } : null;
}

/** Absolute minor units for one currency scale. Mirrors the list SQL. */
export function resolvedMinor(amount: AmountSearch, minorDigits: number): bigint | null {
  if (amount.kind === 'minor') return amount.minor;
  if (!Number.isInteger(minorDigits) || minorDigits < amount.fractionDigits) return null;
  const target = amount.whole * 10n ** BigInt(minorDigits) + amount.fraction * 10n ** BigInt(minorDigits - amount.fractionDigits);
  return target <= INT64_MAX ? target : null;
}
