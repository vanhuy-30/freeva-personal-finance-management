import 'reflect-metadata';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import {
  assertPaletteColor, assertParent, assertTwoLevels, assertVersion, CATEGORY_ICONS, CATEGORY_PALETTE,
  CATEGORY_PICKER_ICONS, DEFAULT_CATEGORIES, iconRefreshPlan, LEGACY_DEFAULT_CATEGORIES, SUPPLEMENT_CATEGORIES,
  supplementPlan, type SupplementRow,
} from './domain/category';
import { CreateCategoryDto, UpdateCategoryDto, CategoryQueryDto, DeleteCategoryDto } from './category.dto';
import { CATEGORY_COLORS } from './category-tokens.generated';
import { CategoryService } from './category.service';
import type { CategoryRepository } from './domain/category.repository';
const uuid = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const check = (dto: object) => validate(dto, { whitelist: true, forbidNonWhitelisted: true });
function row(partial: Partial<SupplementRow> & Pick<SupplementRow, 'id' | 'name'>): SupplementRow {
  return {
    iconToken: null, colorToken: null, parentId: null, isSystem: false, archivedAt: null,
    version: 1, kind: 'both', ...partial,
  };
}
describe('BE-P1-006 domain and DTO', () => {
  it('normalizes name/UUID and permits nullable metadata', async () => {
    const dto = plainToInstance(CreateCategoryDto, { clientId: uuid.toUpperCase(), name: '  Ăn uống  ', parentId: null, colorToken: null, iconToken: null });
    expect(await check(dto)).toHaveLength(0);
    expect(dto.name).toBe('Ăn uống'); expect(dto.clientId).toBe(uuid);
  });
  it.each([{ name: ' ' }, { name: 'x'.repeat(101) }, { parentId: '' }, { iconToken: 'arbitrary' }, { isSystem: true }, { groupId: uuid }, { userId: uuid }, { kind: 'transfer' }])('rejects unsupported create %j', async patch => {
    expect((await check(plainToInstance(CreateCategoryDto, { clientId: uuid, name: 'Valid', ...patch }))).length).toBeGreaterThan(0);
  });
  it.each([{ version: null }, { version: 2147483647 }, { version: 0 }, { version: 1, archived: null }, { version: 1, name: null }, { version: 1, clientId: uuid }, { version: 1, kind: 'income' }])('rejects invalid patch %j', async patch => {
    expect((await check(plainToInstance(UpdateCategoryDto, patch))).length).toBeGreaterThan(0);
  });
  it('accepts the Chi / Thu kind on create (DS-P2-003)', async () => {
    for (const kind of ['expense', 'income', 'both']) {
      expect(await check(plainToInstance(CreateCategoryDto, { clientId: uuid, name: 'Valid', kind }))).toHaveLength(0);
    }
  });
  it('validates pagination/root/deletion and strict versions', async () => {
    expect(await check(plainToInstance(CategoryQueryDto, { parentId: 'root' }))).toHaveLength(0);
    for (const patch of [{ page: 0 }, { pageSize: 101 }, { status: 'deleted' }, { parentId: '' }]) {
      expect((await check(plainToInstance(CategoryQueryDto, patch))).length).toBeGreaterThan(0);
    }
    expect(await check(plainToInstance(DeleteCategoryDto, { version: '1', replacementCategoryId: uuid }))).toHaveLength(0);
    expect(() => assertVersion(2, 1)).toThrow('CATEGORY_CONFLICT');
    expect(() => assertVersion(2147483647, 2147483647)).toThrow('CATEGORY_CONFLICT');
  });
  it('checks ownership, ancestor activity and cycles without a depth limit', () => {
    const tree = Array.from({ length: 200 }, (_, i) => ({ id: `${i}`, parentId: i ? `${i - 1}` : null, archivedAt: null as Date | null }));
    expect(() => assertParent('new', '199', tree, true)).not.toThrow();
    expect(() => assertParent('0', '199', tree, true)).toThrow('VALIDATION_ERROR');
    expect(() => assertParent('new', 'missing', tree, true)).toThrow('CATEGORY_NOT_FOUND');
    tree[0].archivedAt = new Date();
    expect(() => assertParent('new', '199', tree, true)).toThrow('CATEGORY_CONFLICT');
    expect(() => assertParent('new', '199', tree, false)).not.toThrow();
  });
  it('catalog exactly matches design-token names and rejects hex before writing', async () => {
    const tokens = JSON.parse(readFileSync(resolve(__dirname, '../../../../../packages/design-tokens/tokens.json'), 'utf8'));
    const leaves = (node: Record<string, unknown>, prefix = ''): string[] => Object.entries(node).flatMap(([key, value]) => typeof value === 'string' ? [`${prefix}${key}`] : leaves(value as Record<string, unknown>, `${prefix}${key}.`));
    expect(CATEGORY_COLORS).toEqual(leaves({ color: tokens.color }));
    const create = jest.fn();
    const service = new CategoryService({ create } as unknown as CategoryRepository);
    await expect(service.create(uuid, { clientId: uuid, name: 'Valid', colorToken: '#5680E9' })).rejects.toThrow('VALIDATION_ERROR');
    expect(create).not.toHaveBeenCalled();
  });
});
describe('BE-P1-011 supplementPlan', () => {
  it('assigns kinds on pristine legacy system rows and creates missing names under Hóa đơn', () => {
    const rows = LEGACY_DEFAULT_CATEGORIES.map((seed, i) => row({
      id: `00000000-0000-4000-8000-${String(i).padStart(12, '0')}`,
      name: seed.name, iconToken: seed.iconToken, isSystem: true, kind: 'both',
    }));
    const plan = supplementPlan(rows);
    expect(plan.kindUpdates).toEqual(LEGACY_DEFAULT_CATEGORIES.flatMap((seed, index) => seed.kind === 'both' ? [] : [{
      id: `00000000-0000-4000-8000-${String(index).padStart(12, '0')}`, kind: seed.kind,
    }]));
    expect(plan.creates).toHaveLength(SUPPLEMENT_CATEGORIES.length);
    const billsId = rows.find(item => item.name === 'Hóa đơn')!.id;
    for (const name of ['Điện nước', 'Internet', 'Điện thoại']) {
      expect(plan.creates.find(item => item.name === name)).toMatchObject({ parentId: billsId, kind: 'expense' });
    }
  });
  it('skips kind when renamed or versioned and does not duplicate existing names', () => {
    const bills = row({ id: 'bills', name: 'Hóa đơn', iconToken: 'bills', isSystem: true, kind: 'both' });
    const renamed = row({ id: 'food', name: 'Ăn ngoài', iconToken: 'food', isSystem: true, kind: 'both' });
    const bumped = row({ id: 'salary', name: 'Lương', iconToken: 'salary', isSystem: true, version: 2, kind: 'both' });
    const customCafe = row({ id: 'cafe', name: 'Cà phê', iconToken: 'food', isSystem: false, kind: 'both' });
    const plan = supplementPlan([bills, renamed, bumped, customCafe]);
    expect(plan.kindUpdates.find(item => item.id === 'food')).toBeUndefined();
    expect(plan.kindUpdates.find(item => item.id === 'salary')).toBeUndefined();
    expect(plan.creates.find(item => item.name === 'Cà phê')).toBeUndefined();
    expect(plan.creates.find(item => item.name === 'Điện nước')?.parentId).toBe('bills');
  });
  it('creates utility roots when Hóa đơn is archived or missing', () => {
    const archived = row({ id: 'bills', name: 'Hóa đơn', iconToken: 'bills', isSystem: true, archivedAt: new Date(), kind: 'both' });
    expect(supplementPlan([archived]).creates.find(item => item.name === 'Internet')?.parentId).toBeNull();
    expect(supplementPlan([]).creates.find(item => item.name === 'Internet')?.parentId).toBeNull();
  });
  it('returns empty creates and kind updates when already complete', () => {
    const rows = [
      ...LEGACY_DEFAULT_CATEGORIES.map((seed, i) => row({
        id: `l${i}`, name: seed.name, iconToken: seed.iconToken, isSystem: true, kind: seed.kind,
      })),
      ...SUPPLEMENT_CATEGORIES.map((seed, i) => row({
        id: `s${i}`, name: seed.name, iconToken: seed.iconToken, isSystem: true, kind: seed.kind,
        parentId: seed.parentName ? 'l3' : null,
      })),
    ];
    expect(supplementPlan(rows)).toEqual({ kindUpdates: [], creates: [] });
  });
});
describe('DS-P2-003 group E rules', () => {
  it('allows two levels only; deeper legacy rows are not re-checked here', () => {
    const tree = [
      { id: 'root', parentId: null }, { id: 'child', parentId: 'root' }, { id: 'lone', parentId: null },
    ];
    expect(() => assertTwoLevels('new', 'root', tree)).not.toThrow();
    expect(() => assertTwoLevels('new', null, tree)).not.toThrow();
    expect(() => assertTwoLevels('new', 'child', tree)).toThrow('VALIDATION_ERROR');
    expect(() => assertTwoLevels('lone', 'lone', tree)).toThrow('VALIDATION_ERROR');
    expect(() => assertTwoLevels('root', 'lone', tree)).toThrow('CATEGORY_CONFLICT');
    expect(() => assertTwoLevels('new', 'missing', tree)).toThrow('CATEGORY_NOT_FOUND');
  });
  it('palette has 20 distinct catalog colours without the error red; old keys only when unchanged', () => {
    expect(new Set(CATEGORY_PALETTE).size).toBe(20);
    for (const color of CATEGORY_PALETTE) expect(CATEGORY_COLORS).toContain(color);
    expect(CATEGORY_PALETTE).not.toContain('color.semantic.danger');
    expect(() => assertPaletteColor('color.category.pink')).not.toThrow();
    expect(() => assertPaletteColor(null)).not.toThrow();
    expect(() => assertPaletteColor('color.semantic.danger')).toThrow('VALIDATION_ERROR');
    expect(() => assertPaletteColor('color.semantic.danger', 'color.semantic.danger')).not.toThrow();
  });
  it('offers 36 picker icons and keeps every older token valid', () => {
    expect(new Set(CATEGORY_PICKER_ICONS).size).toBe(36);
    for (const old of ['category', 'food', 'transport', 'housing', 'bills', 'shopping', 'health', 'education',
      'entertainment', 'family', 'gifts', 'travel', 'salary', 'bonus', 'other_income', 'other_expense']) {
      expect(CATEGORY_ICONS).toContain(old);
    }
    for (const seed of DEFAULT_CATEGORIES) expect(CATEGORY_ICONS).toContain(seed.iconToken);
  });
  it('refreshes icons only on untouched system defaults', () => {
    expect(iconRefreshPlan([
      { id: '1', name: 'Cà phê', iconToken: 'food', isSystem: true },
      { id: '2', name: 'Internet', iconToken: 'bills', isSystem: true },
      { id: '3', name: 'Cà phê', iconToken: 'gifts', isSystem: true },
      { id: '4', name: 'Internet', iconToken: 'bills', isSystem: false },
      { id: '5', name: 'Ăn uống', iconToken: 'food', isSystem: true },
    ])).toEqual([{ id: '1', iconToken: 'coffee' }, { id: '2', iconToken: 'internet' }]);
  });
  it('options list the palette and picker icons in display order', () => {
    const options = new CategoryService({} as CategoryRepository).options();
    expect(options.colorTokens).toEqual(CATEGORY_PALETTE);
    expect(options.iconTokens).toEqual(CATEGORY_PICKER_ICONS);
  });
});
