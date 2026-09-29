export class CategoryError extends Error {
  constructor(readonly code: 'VALIDATION_ERROR' | 'CATEGORY_NOT_FOUND' | 'CATEGORY_CONFLICT') { super(code); }
}
export const CATEGORY_ICONS = ['category', 'food', 'transport', 'housing', 'bills', 'shopping', 'health', 'education', 'entertainment', 'family', 'gifts', 'travel', 'salary', 'bonus', 'other_income', 'other_expense'] as const;
export const DEFAULT_CATEGORIES = [
  ['Ăn uống', 'food'], ['Đi lại', 'transport'], ['Nhà ở', 'housing'], ['Hóa đơn', 'bills'],
  ['Mua sắm', 'shopping'], ['Sức khỏe', 'health'], ['Giáo dục', 'education'], ['Giải trí', 'entertainment'],
  ['Gia đình', 'family'], ['Quà tặng', 'gifts'], ['Du lịch', 'travel'], ['Lương', 'salary'],
  ['Thưởng', 'bonus'], ['Thu nhập khác', 'other_income'], ['Chi khác', 'other_expense'],
] as const;
export interface CategoryInput {
  clientId: string;
  name: string;
  parentId: string | null;
  colorToken: string | null;
  iconToken: string | null;
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
export function assertVersion(actual: number, expected: number) {
  if (actual !== expected || actual >= 2147483647) throw new CategoryError('CATEGORY_CONFLICT');
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
