/**
 * BE-P5-E03: guess a category from a merchant or a note. Pure: the service loads the rows,
 * this decides. Order: what the user remembered, then the user's own history, then the
 * common merchant list from app config. Nothing here saves a transaction.
 */

export type SuggestionSource = 'remembered' | 'history' | 'common';
export type SuggestKind = 'expense' | 'income';

export interface SuggestCategory {
  id: string;
  name: string;
  iconToken: string | null;
  colorToken: string | null;
  kind: 'expense' | 'income' | 'both';
  isSystem: boolean;
  parentId: string | null;
  archivedAt: Date | null;
}

export interface Suggestion {
  category: Pick<SuggestCategory, 'id' | 'name' | 'iconToken' | 'colorToken'>;
  source: SuggestionSource;
  /** Past transactions at this merchant (or with this note) filed under the category; 0 for the common list. */
  matchCount: number;
  /** Share of those past transactions, 0–100; null for the common list. */
  confidencePercent: number | null;
}

export interface SuggestInput {
  merchant: string | null;
  note: string | null;
  kind: SuggestKind;
  /** Category id the user remembered for this merchant, if any. */
  rememberedCategoryId: string | null;
  /** Category ids of the user's most recent transactions with the same merchant (or note), newest first. */
  history: string[];
  /** Active and archived categories of the user. */
  categories: SuggestCategory[];
  /** `categorySuggest.commonMerchants`, entries `merchant: iconToken`. */
  commonMerchants: readonly string[];
  minConfidencePercent: number;
}

/** Lower case, no diacritics, `đ` → `d`, every run of non letters/digits one space. Used for the common list. */
export function looseText(text: string): string {
  return text
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/đ/gi, 'd')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, ' ')
    .trim();
}

/** `"Grab: transport"` → `{ match: 'grab', target: 'transport' }`; null when the entry is not of that shape. */
export function parseCommonMerchant(entry: string): { match: string; target: string } | null {
  const at = entry.lastIndexOf(':');
  if (at <= 0) return null;
  const match = looseText(entry.slice(0, at));
  const target = entry.slice(at + 1).trim();
  return match && target ? { match, target } : null;
}

/** Category icons a common-list target falls back to when the user has no category with that icon. */
const TARGET_FALLBACK: Record<string, string[]> = {
  groceries: ['food'], coffee: ['food'], fuel: ['transport'], bus: ['transport'], medicine: ['health'],
  clothes: ['shopping'], beauty: ['shopping'], water: ['electricity'], internet: ['electricity'], phone: ['electricity'],
  games: ['entertainment'], music: ['entertainment'], books: ['education'],
};

function fits(category: SuggestCategory | undefined, kind: SuggestKind): category is SuggestCategory {
  return !!category && category.archivedAt === null && (category.kind === 'both' || category.kind === kind);
}

const view = (c: SuggestCategory) => ({ id: c.id, name: c.name, iconToken: c.iconToken, colorToken: c.colorToken });

function byIcon(categories: SuggestCategory[], icon: string, kind: SuggestKind): SuggestCategory | undefined {
  const candidates = categories.filter(c => c.iconToken === icon && fits(c, kind));
  // Default categories first, then top level, then name, so the pick is stable.
  candidates.sort((a, b) =>
    Number(b.isSystem) - Number(a.isSystem) || Number(a.parentId !== null) - Number(b.parentId !== null) || a.name.localeCompare(b.name, 'vi'));
  return candidates[0];
}

/** Longest common-list entry whose words appear, as whole words, in the merchant or the note. */
export function matchCommon(texts: string[], entries: readonly string[]): string | null {
  const haystacks = texts.map(t => ` ${looseText(t)} `).filter(t => t.trim() !== '');
  let best: { match: string; target: string } | null = null;
  for (const entry of entries) {
    const parsed = parseCommonMerchant(entry);
    if (!parsed) continue;
    if (!haystacks.some(h => h.includes(` ${parsed.match} `))) continue;
    if (!best || parsed.match.length > best.match.length) best = parsed;
  }
  return best?.target ?? null;
}

export function suggestCategory(input: SuggestInput): Suggestion | null {
  const merchant = input.merchant?.trim() || null;
  const note = input.note?.trim() || null;
  if (!merchant && !note) return null;
  const categories = new Map(input.categories.map(c => [c.id, c]));
  const counts = new Map<string, number>();
  for (const id of input.history) counts.set(id, (counts.get(id) ?? 0) + 1);

  const remembered = input.rememberedCategoryId ? categories.get(input.rememberedCategoryId) : undefined;
  if (merchant && fits(remembered, input.kind)) {
    const matches = counts.get(remembered.id) ?? 0;
    return {
      category: view(remembered), source: 'remembered', matchCount: matches,
      confidencePercent: input.history.length ? Math.round((matches * 100) / input.history.length) : null,
    };
  }

  // Only categories still usable count; the top one must hold at least the configured share.
  const usable = [...counts].filter(([id]) => fits(categories.get(id), input.kind));
  const total = usable.reduce((sum, [, n]) => sum + n, 0);
  if (total > 0) {
    usable.sort((a, b) => b[1] - a[1]);
    const [topId, topCount] = usable[0];
    const tie = usable.length > 1 && usable[1][1] === topCount;
    const percent = Math.round((topCount * 100) / total);
    if (!tie && percent >= input.minConfidencePercent) {
      return { category: view(categories.get(topId)!), source: 'history', matchCount: topCount, confidencePercent: percent };
    }
    // The user's own history disagrees with itself: say nothing rather than fall back to the common list.
    return null;
  }

  const target = matchCommon([merchant ?? '', note ?? ''], input.commonMerchants);
  if (!target) return null;
  for (const icon of [target, ...(TARGET_FALLBACK[target] ?? [])]) {
    const category = byIcon(input.categories, icon, input.kind);
    if (category) return { category: view(category), source: 'common', matchCount: 0, confidencePercent: null };
  }
  return null;
}

/** Default common merchants (Vietnam). Staff edit the list on web admin (`categorySuggest.commonMerchants`). */
export const DEFAULT_COMMON_MERCHANTS: readonly string[] = [
  'Grab: transport', 'Xanh SM: transport', 'Gojek: transport', 'Be Group: transport', 'Petrolimex: fuel',
  'GrabFood: food', 'ShopeeFood: food', 'KFC: food', 'Lotteria: food', 'Jollibee: food', "McDonald's: food", 'Pizza Hut: food',
  'Highlands: coffee', 'The Coffee House: coffee', 'Phúc Long: coffee', 'Starbucks: coffee', 'Katinat: coffee', 'Trung Nguyên: coffee',
  'WinMart: groceries', 'Bách Hóa Xanh: groceries', 'Co.opmart: groceries', 'Circle K: food', 'GS25: food', '7-Eleven: food',
  'Shopee: shopping', 'Lazada: shopping', 'Tiki: shopping', 'TikTok Shop: shopping', 'Điện Máy Xanh: shopping', 'Thế Giới Di Động: shopping',
  'Netflix: subscription', 'Spotify: subscription', 'YouTube Premium: subscription', 'iCloud: subscription',
  'CGV: entertainment', 'Lotte Cinema: entertainment', 'Galaxy Cinema: entertainment',
  'EVN: electricity', 'Viettel: phone', 'Vinaphone: phone', 'Mobifone: phone', 'FPT Telecom: internet', 'VNPT: internet',
  'Pharmacity: medicine', 'Long Châu: medicine', 'An Khang: medicine',
  'Vietjet: travel', 'Vietnam Airlines: travel', 'Bamboo Airways: travel', 'Traveloka: travel', 'Agoda: travel',
];
