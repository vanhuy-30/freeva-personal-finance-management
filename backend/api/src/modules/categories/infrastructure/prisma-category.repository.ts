import { randomUUID } from 'node:crypto';
import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import { touchFinancialOwner } from '../../../infrastructure/prisma/financial-owner-lock';
import type { CategoryRepository } from '../domain/category.repository';
import {
  assertPaletteColor, assertParent, assertTwoLevels, assertVersion, CategoryError, DEFAULT_CATEGORIES, iconRefreshPlan,
  supplementPlan,
  type Category, type CategoryInput, type CategoryPatch, type CategoryQuery, type SupplementRow,
} from '../domain/category';
// Explicit public projection: never return userId or internal account data.
const select = { id: true, clientId: true, name: true, kind: true, parentId: true, groupId: true, colorToken: true, iconToken: true,
  isSystem: true, archivedAt: true, version: true, createdAt: true, updatedAt: true } satisfies Prisma.CategorySelect;
const supplementSelect = { id: true, name: true, kind: true, iconToken: true, colorToken: true, parentId: true,
  isSystem: true, archivedAt: true, version: true } satisfies Prisma.CategorySelect;
@Injectable()
export class PrismaCategoryRepository implements CategoryRepository {
  constructor(private readonly prisma: PrismaService) {}
  private async write<T>(userId: string, operation: (tx: Prisma.TransactionClient) => Promise<T>): Promise<T> {
    for (let attempt = 0; ; attempt++) {
      try {
        return await this.prisma.$transaction(async tx => {
          await touchFinancialOwner(tx, userId);
          return operation(tx);
        }, { isolationLevel: Prisma.TransactionIsolationLevel.RepeatableRead });
      } catch (error) {
        if (attempt < 3 && error instanceof Prisma.PrismaClientKnownRequestError && (error.code === 'P2034' || error.code === 'P2002' ||
          (error.code === 'P2010' && ['40001', '40P01'].includes(String(error.meta?.code))))) continue;
        throw error;
      }
    }
  }
  private async get(tx: Prisma.TransactionClient, userId: string, id: string): Promise<Category> {
    const row = await tx.category.findFirst({ where: { id, userId }, select });
    if (!row) throw new CategoryError('CATEGORY_NOT_FOUND');
    return row;
  }
  private async seedDefaults(tx: Prisma.TransactionClient, userId: string) {
    const byName = new Map<string, string>();
    const roots = DEFAULT_CATEGORIES.filter(seed => !seed.parentName);
    const children = DEFAULT_CATEGORIES.filter(seed => seed.parentName);
    for (const seed of roots) {
      const row = await tx.category.create({
        data: {
          userId, clientId: randomUUID(), name: seed.name, kind: seed.kind, iconToken: seed.iconToken, isSystem: true,
        },
        select: { id: true, name: true },
      });
      byName.set(row.name, row.id);
    }
    for (const seed of children) {
      const parentId = seed.parentName ? byName.get(seed.parentName) ?? null : null;
      await tx.category.create({
        data: {
          userId, clientId: randomUUID(), name: seed.name, kind: seed.kind, iconToken: seed.iconToken,
          parentId, isSystem: true,
        },
      });
    }
  }
  private async applySupplement(tx: Prisma.TransactionClient, userId: string, rows: SupplementRow[]) {
    const plan = supplementPlan(rows);
    for (const update of plan.kindUpdates) {
      await tx.category.update({ where: { id: update.id }, data: { kind: update.kind } });
    }
    for (const create of plan.creates) {
      await tx.category.create({
        data: {
          userId, clientId: randomUUID(), name: create.name, kind: create.kind,
          iconToken: create.iconToken, parentId: create.parentId, isSystem: true,
        },
      });
    }
  }
  /** Specific icons for untouched system defaults; bumps version so other devices refetch. */
  private async refreshIcons(tx: Prisma.TransactionClient, userId: string) {
    const rows = await tx.category.findMany({ where: { userId }, select: supplementSelect });
    for (const update of iconRefreshPlan(rows)) {
      await tx.category.update({ where: { id: update.id }, data: { iconToken: update.iconToken, version: { increment: 1 } } });
    }
  }
  initialize(userId: string) {
    return this.write(userId, async tx => {
      const owner = await tx.user.findUniqueOrThrow({
        where: { id: userId },
        select: { categoriesInitializedAt: true, categoriesSupplementedAt: true, categoryIconsRefreshedAt: true },
      });
      const now = new Date();
      if (!owner.categoriesInitializedAt) {
        await this.seedDefaults(tx, userId);
        await tx.user.update({
          where: { id: userId },
          data: { categoriesInitializedAt: now, categoriesSupplementedAt: now, categoryIconsRefreshedAt: now },
        });
        return;
      }
      if (!owner.categoriesSupplementedAt) {
        const rows = await tx.category.findMany({ where: { userId }, select: supplementSelect });
        await this.applySupplement(tx, userId, rows);
        await tx.user.update({ where: { id: userId }, data: { categoriesSupplementedAt: now } });
      }
      if (owner.categoryIconsRefreshedAt) return;
      await this.refreshIcons(tx, userId);
      await tx.user.update({ where: { id: userId }, data: { categoryIconsRefreshedAt: now } });
    });
  }
  create(userId: string, input: CategoryInput) {
    return this.write(userId, async tx => {
      const tree = await tx.category.findMany({ where: { userId }, select });
      // A subcategory always has its parent's kind; normalize before comparing a replay.
      const parent = input.parentId ? tree.find(row => row.id === input.parentId) : undefined;
      if (parent) input = { ...input, kind: parent.kind };
      const existing = await tx.category.findUnique({ where: { userId_clientId: { userId, clientId: input.clientId } }, select });
      if (existing) {
        if (existing.isSystem || (Object.keys(input) as (keyof CategoryInput)[]).some(key => existing[key] !== input[key])) throw new CategoryError('CATEGORY_CONFLICT');
        return { category: existing, created: false };
      }
      assertTwoLevels(undefined, input.parentId, tree);
      assertParent(undefined, input.parentId, tree, true);
      return { category: await tx.category.create({ data: { ...input, userId }, select }), created: true };
    });
  }
  find(userId: string, id: string) { return this.get(this.prisma, userId, id); }
  list(userId: string, query: CategoryQuery) {
    return this.prisma.$transaction(async tx => {
      // A foreign parent is indistinguishable from a missing one, including archived parents.
      if (query.parentId && query.parentId !== 'root') await this.get(tx, userId, query.parentId);
      const where: Prisma.CategoryWhereInput = { userId,
        ...(query.status === 'all' ? {} : { archivedAt: query.status === 'active' ? null : { not: null } }),
        ...(query.parentId === undefined ? {} : { parentId: query.parentId === 'root' ? null : query.parentId }) };
      const items = await tx.category.findMany({ where, select, orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
        skip: (query.page - 1) * query.pageSize, take: query.pageSize });
      return { items, total: await tx.category.count({ where }) };
    }, { isolationLevel: Prisma.TransactionIsolationLevel.RepeatableRead });
  }
  recent(userId: string) {
    return this.prisma.$transaction(async tx => {
      const groups = await tx.transaction.groupBy({ by: ['categoryId'],
        where: { userId, deletedAt: null, categoryId: { not: null }, category: { userId, archivedAt: null } },
        _max: { createdAt: true }, orderBy: [{ _max: { createdAt: 'desc' } }, { categoryId: 'asc' }], take: 10 });
      const ids = groups.map(row => row.categoryId!);
      const rows = await tx.category.findMany({ where: { userId, id: { in: ids }, archivedAt: null }, select });
      const byId = new Map(rows.map(row => [row.id, row]));
      return ids.map(id => byId.get(id)!);
    }, { isolationLevel: Prisma.TransactionIsolationLevel.RepeatableRead });
  }
  update(userId: string, id: string, patch: CategoryPatch) {
    return this.write(userId, async tx => {
      const current = await this.get(tx, userId, id);
      assertVersion(current.version, patch.version);
      const tree = await tx.category.findMany({ where: { userId }, select });
      const archived = patch.archived ?? (current.archivedAt !== null);
      if (archived && tree.some(row => row.parentId === id && !row.archivedAt)) throw new CategoryError('CATEGORY_CONFLICT');
      assertPaletteColor(patch.colorToken, current.colorToken);
      const moved = patch.parentId !== undefined && patch.parentId !== current.parentId;
      if (moved) assertTwoLevels(id, patch.parentId ?? null, tree);
      assertParent(id, patch.parentId === undefined ? current.parentId : patch.parentId, tree, !archived);
      const { version: _version, archived: _archived, ...fields } = patch;
      // Moving under a parent takes its kind, so the subcategory stays on the same Chi / Thu tab.
      const parent = moved && patch.parentId ? tree.find(row => row.id === patch.parentId) : undefined;
      return tx.category.update({ where: { id, userId, version: patch.version }, data: { ...fields,
        ...(parent ? { kind: parent.kind } : {}),
        archivedAt: archived ? current.archivedAt ?? new Date() : null, version: { increment: 1 } }, select });
    });
  }
  delete(userId: string, id: string, version: number, replacementCategoryId?: string) {
    return this.write(userId, async tx => {
      const current = await this.get(tx, userId, id);
      assertVersion(current.version, version);
      if (await tx.category.count({ where: { userId, parentId: id } })) throw new CategoryError('CATEGORY_CONFLICT');
      if (replacementCategoryId) {
        if (replacementCategoryId === id) throw new CategoryError('VALIDATION_ERROR');
        const target = await this.get(tx, userId, replacementCategoryId);
        if (target.archivedAt) throw new CategoryError('CATEGORY_CONFLICT');
      }
      const where = { userId, categoryId: id };
      if (await tx.transaction.count({ where })) {
        if (!replacementCategoryId || await tx.transaction.count({ where: { ...where, version: { gte: 2147483647 } } })) throw new CategoryError('CATEGORY_CONFLICT');
        await tx.transaction.updateMany({ where, data: { categoryId: replacementCategoryId, version: { increment: 1 }, updatedAt: new Date() } });
      }
      await tx.category.delete({ where: { id, userId, version } });
    });
  }
}
