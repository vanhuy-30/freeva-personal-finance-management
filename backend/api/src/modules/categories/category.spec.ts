import 'reflect-metadata';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import {
  assertParent, assertVersion, LEGACY_DEFAULT_CATEGORIES, SUPPLEMENT_CATEGORIES, supplementPlan,
  type SupplementRow,
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
  it.each([{ name: ' ' }, { name: 'x'.repeat(101) }, { parentId: '' }, { iconToken: 'arbitrary' }, { isSystem: true }, { groupId: uuid }, { userId: uuid }, { kind: 'expense' }])('rejects unsupported create %j', async patch => {
    expect((await check(plainToInstance(CreateCategoryDto, { clientId: uuid, name: 'Valid', ...patch }))).length).toBeGreaterThan(0);
  });
  it.each([{ version: null }, { version: 2147483647 }, { version: 0 }, { version: 1, archived: null }, { version: 1, name: null }, { version: 1, clientId: uuid }, { version: 1, kind: 'income' }])('rejects invalid patch %j', async patch => {
    expect((await check(plainToInstance(UpdateCategoryDto, patch))).length).toBeGreaterThan(0);
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
