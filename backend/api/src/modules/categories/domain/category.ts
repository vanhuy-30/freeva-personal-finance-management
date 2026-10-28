export class CategoryError extends Error {
  constructor(readonly code: 'VALIDATION_ERROR' | 'CATEGORY_NOT_FOUND' | 'CATEGORY_CONFLICT') { super(code); }
}
/**
 * The 36 icons offered by the picker (DS-P2-003, group E), in picker order and four groups. Older tokens keep their
 * meaning: `entertainment` is "phim", `bills` is "thuế/phí", `other_income` is "tiết kiệm", `other_expense` is "khác".
 */
export const CATEGORY_PICKER_ICONS = [
  'food', 'coffee', 'groceries', 'shopping', 'clothes', 'gifts',
  'transport', 'bus', 'fuel', 'travel', 'housing', 'repair', 'electricity', 'water', 'internet', 'phone',
  'health', 'medicine', 'sports', 'family', 'pets', 'beauty', 'education', 'books', 'music', 'entertainment', 'games',
  'salary', 'bonus', 'investment', 'work', 'other_income', 'bills', 'insurance', 'subscription', 'other_expense',
] as const;
/** Every accepted icon: the picker set plus `category`, kept for rows saved before DS-P2-003. */
export const CATEGORY_ICONS = ['category', ...CATEGORY_PICKER_ICONS] as const;
/**
 * Colour grid order (after "no colour", which is null): 20 legacy `color.*` keys. Writes may only pick these; a row
 * that already holds another catalog key keeps it until changed.
 */
export const CATEGORY_PALETTE = [
  'color.brand.primary', 'color.category.blueDeep', 'color.brand.secondary', 'color.category.oceanDeep',
  'color.brand.accent', 'color.category.violetDeep',
  'color.semantic.success', 'color.semantic.warning', 'color.category.blueLight', 'color.brand.highlight',
  'color.category.violetLight', 'color.category.greenLight', 'color.category.yellowLight',
  'color.category.pink', 'color.category.orange', 'color.category.brown', 'color.category.lime',
  'color.category.olive', 'color.category.plum', 'color.category.gray',
] as const;
export const CATEGORY_KINDS = ['expense', 'income', 'both'] as const;
export type CategoryKind = 'expense' | 'income' | 'both';
export type CategoryIcon = (typeof CATEGORY_ICONS)[number];
export interface DefaultCategorySeed {
  name: string;
  iconToken: CategoryIcon;
  kind: CategoryKind;
  /** Exact parent name; null = root. Only used when that parent is still active. */
  parentName: string | null;
}
/** Original BE-P1-006 roots; kinds assigned on fresh bootstrap and on supplement. */
export const LEGACY_DEFAULT_CATEGORIES: readonly DefaultCategorySeed[] = [
  { name: 'Ăn uống', iconToken: 'food', kind: 'expense', parentName: null },
  { name: 'Đi lại', iconToken: 'transport', kind: 'expense', parentName: null },
  { name: 'Nhà ở', iconToken: 'housing', kind: 'expense', parentName: null },
  { name: 'Hóa đơn', iconToken: 'electricity', kind: 'expense', parentName: null },
  { name: 'Mua sắm', iconToken: 'shopping', kind: 'expense', parentName: null },
  { name: 'Sức khỏe', iconToken: 'health', kind: 'expense', parentName: null },
  { name: 'Giáo dục', iconToken: 'education', kind: 'expense', parentName: null },
  { name: 'Giải trí', iconToken: 'entertainment', kind: 'expense', parentName: null },
  { name: 'Gia đình', iconToken: 'family', kind: 'expense', parentName: null },
  { name: 'Quà tặng', iconToken: 'gifts', kind: 'both', parentName: null },
  { name: 'Du lịch', iconToken: 'travel', kind: 'expense', parentName: null },
  { name: 'Lương', iconToken: 'salary', kind: 'income', parentName: null },
  { name: 'Thưởng', iconToken: 'bonus', kind: 'income', parentName: null },
  { name: 'Thu nhập khác', iconToken: 'other_income', kind: 'income', parentName: null },
  { name: 'Chi khác', iconToken: 'other_expense', kind: 'expense', parentName: null },
];
/** Spec names missing from the original 15; added once via supplement or fresh bootstrap. */
export const SUPPLEMENT_CATEGORIES: readonly DefaultCategorySeed[] = [
  { name: 'Cà phê', iconToken: 'coffee', kind: 'expense', parentName: null },
  { name: 'Điện nước', iconToken: 'electricity', kind: 'expense', parentName: 'Hóa đơn' },
  { name: 'Internet', iconToken: 'internet', kind: 'expense', parentName: 'Hóa đơn' },
  { name: 'Điện thoại', iconToken: 'phone', kind: 'expense', parentName: 'Hóa đơn' },
  { name: 'Subscription', iconToken: 'subscription', kind: 'expense', parentName: null },
  { name: 'Bảo hiểm', iconToken: 'insurance', kind: 'expense', parentName: null },
  { name: 'Thuế/phí', iconToken: 'bills', kind: 'expense', parentName: null },
  { name: 'Freelance', iconToken: 'work', kind: 'income', parentName: null },
  { name: 'Kinh doanh', iconToken: 'work', kind: 'income', parentName: null },
  { name: 'Đầu tư', iconToken: 'investment', kind: 'income', parentName: null },
  { name: 'Hoàn tiền', iconToken: 'other_income', kind: 'income', parentName: null },
];
export const DEFAULT_CATEGORIES: readonly DefaultCategorySeed[] = [...LEGACY_DEFAULT_CATEGORIES, ...SUPPLEMENT_CATEGORIES];
/** Icons the supplement defaults had before DS-P2-003 (all generic). */
const PREVIOUS_SUPPLEMENT_ICONS: Readonly<Record<string, CategoryIcon>> = {
  'Cà phê': 'food', 'Điện nước': 'bills', Internet: 'bills', 'Điện thoại': 'bills', Subscription: 'category',
  'Bảo hiểm': 'health', 'Thuế/phí': 'category', Freelance: 'other_income', 'Kinh doanh': 'other_income',
  'Đầu tư': 'other_income',
};
/**
 * One-shot icon refresh: system defaults that still have their old name and old generic icon get the specific icon.
 * Anything the user renamed or re-iconed is left alone.
 */
export function iconRefreshPlan(rows: Pick<SupplementRow, 'id' | 'name' | 'iconToken' | 'isSystem'>[]): Array<{ id: string; iconToken: CategoryIcon }> {
  return rows.flatMap(row => {
    const previous = PREVIOUS_SUPPLEMENT_ICONS[row.name];
    const seed = SUPPLEMENT_CATEGORIES.find(item => item.name === row.name);
    return row.isSystem && previous && seed && row.iconToken === previous ? [{ id: row.id, iconToken: seed.iconToken }] : [];
  });
}
export interface CategoryInput {
  clientId: string;
  name: string;
  parentId: string | null;
  colorToken: string | null;
  iconToken: string | null;
  /** Ignored for a subcategory, which takes its parent's kind. */
  kind: CategoryKind;
}
export interface Category extends CategoryInput {
  id: string;
  groupId: string | null;
  isSystem: boolean;
  archivedAt: Date | null;
  version: number;
  createdAt: Date;
  updatedAt: Date;
}
export interface CategoryPatch {
  version: number;
  name?: string;
  parentId?: string | null;
  colorToken?: string | null;
  iconToken?: string | null;
  archived?: boolean;
}
export interface CategoryQuery {
  page: number;
  pageSize: number;
  status: 'active' | 'archived' | 'all';
  parentId?: string | 'root';
}
export interface SupplementRow {
  id: string;
  name: string;
  iconToken: string | null;
  colorToken: string | null;
  parentId: string | null;
  isSystem: boolean;
  archivedAt: Date | null;
  version: number;
  kind: CategoryKind;
}
export interface SupplementCreate {
  name: string;
  iconToken: CategoryIcon;
  kind: CategoryKind;
  parentId: string | null;
}
export interface SupplementPlan {
  kindUpdates: Array<{ id: string; kind: CategoryKind }>;
  creates: SupplementCreate[];
}
function isPristineLegacy(row: SupplementRow, seed: DefaultCategorySeed): boolean {
  return row.isSystem
    && row.version === 1
    && row.archivedAt === null
    && row.parentId === null
    && row.colorToken === null
    && row.name === seed.name
    && row.iconToken === seed.iconToken;
}
/** Prefer an active system "Hóa đơn"; otherwise any active exact name. */
export function resolveActiveParentId(rows: SupplementRow[], parentName: string): string | null {
  const matches = rows.filter(row => row.name === parentName && row.archivedAt === null);
  const system = matches.find(row => row.isSystem);
  return (system ?? matches[0])?.id ?? null;
}
/**
 * One-shot plan: assign kinds on untouched legacy system defaults; create missing
 * supplement names without renaming or duplicating existing rows.
 */
export function supplementPlan(rows: SupplementRow[]): SupplementPlan {
  const kindUpdates: SupplementPlan['kindUpdates'] = [];
  for (const seed of LEGACY_DEFAULT_CATEGORIES) {
    const row = rows.find(item => isPristineLegacy(item, seed));
    if (row && row.kind !== seed.kind) kindUpdates.push({ id: row.id, kind: seed.kind });
  }
  const names = new Set(rows.map(row => row.name));
  const creates: SupplementCreate[] = [];
  for (const seed of SUPPLEMENT_CATEGORIES) {
    if (names.has(seed.name)) continue;
    names.add(seed.name);
    const parentId = seed.parentName ? resolveActiveParentId(rows, seed.parentName) : null;
    creates.push({ name: seed.name, iconToken: seed.iconToken, kind: seed.kind, parentId });
  }
  return { kindUpdates, creates };
}
export function assertVersion(actual: number, expected: number) {
  if (actual !== expected || actual >= 2147483647) throw new CategoryError('CATEGORY_CONFLICT');
}
/**
 * Two levels only (DS-P2-003): a new parent must be a root of the owner, and a category that has
 * children cannot become a child. Rows nested deeper before this rule stay readable and editable in place.
 */
export function assertTwoLevels(id: string | undefined, parentId: string | null, tree: Pick<Category, 'id' | 'parentId'>[]) {
  if (!parentId) return;
  const parent = tree.find(item => item.id === parentId);
  if (!parent) throw new CategoryError('CATEGORY_NOT_FOUND');
  if (parentId === id || parent.parentId !== null) throw new CategoryError('VALIDATION_ERROR');
  if (id && tree.some(item => item.parentId === id)) throw new CategoryError('CATEGORY_CONFLICT');
}
/** A write may pick a palette colour or none; any other catalog key only when it is the row's current value. */
export function assertPaletteColor(color: string | null | undefined, current?: string | null) {
  if (color == null || color === current) return;
  if (!(CATEGORY_PALETTE as readonly string[]).includes(color)) throw new CategoryError('VALIDATION_ERROR');
}
/** All ancestors must exist in the owner's tree; tolerate arbitrary valid depth. */
export function assertParent(id: string | undefined, parentId: string | null, tree: Pick<Category, 'id' | 'parentId' | 'archivedAt'>[], active: boolean) {
  const nodes = new Map(tree.map(item => [item.id, item]));
  const seen = new Set(id ? [id] : []);
  let cursor = parentId;
  while (cursor) {
    if (seen.has(cursor)) throw new CategoryError('VALIDATION_ERROR');
    seen.add(cursor);
    const parent = nodes.get(cursor);
    if (!parent) throw new CategoryError('CATEGORY_NOT_FOUND');
    if (active && parent.archivedAt) throw new CategoryError('CATEGORY_CONFLICT');
    cursor = parent.parentId;
  }
}
