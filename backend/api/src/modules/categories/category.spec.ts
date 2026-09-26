import 'reflect-metadata';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { assertParent, assertVersion } from './domain/category';
import { CreateCategoryDto, UpdateCategoryDto, CategoryQueryDto, DeleteCategoryDto } from './category.dto';
import { CATEGORY_COLORS } from './category-tokens.generated';
import { CategoryService } from './category.service';
import type { CategoryRepository } from './domain/category.repository';
const uuid = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const check = (dto: object) => validate(dto, { whitelist: true, forbidNonWhitelisted: true });
describe('BE-P1-006 domain and DTO', () => {
  it('normalizes name/UUID and permits nullable metadata', async () => {
    const dto = plainToInstance(CreateCategoryDto, { clientId: uuid.toUpperCase(), name: '  Ăn uống  ', parentId: null, colorToken: null, iconToken: null });
    expect(await check(dto)).toHaveLength(0);
    expect(dto.name).toBe('Ăn uống'); expect(dto.clientId).toBe(uuid);
  });
  it.each([{ name: ' ' }, { name: 'x'.repeat(101) }, { parentId: '' }, { iconToken: 'arbitrary' }, { isSystem: true }, { groupId: uuid }, { userId: uuid }])('rejects unsupported create %j', async patch => {
    expect((await check(plainToInstance(CreateCategoryDto, { clientId: uuid, name: 'Valid', ...patch }))).length).toBeGreaterThan(0);
  });
  it.each([{ version: null }, { version: 2147483647 }, { version: 0 }, { version: 1, archived: null }, { version: 1, name: null }, { version: 1, clientId: uuid }])('rejects invalid patch %j', async patch => {
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
