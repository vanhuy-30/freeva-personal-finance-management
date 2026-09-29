import { randomUUID } from 'node:crypto';
import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import { touchFinancialOwner } from '../../../infrastructure/prisma/financial-owner-lock';
import type { CategoryRepository } from '../domain/category.repository';
import { assertParent, assertVersion, CategoryError, DEFAULT_CATEGORIES, type Category, type CategoryInput, type CategoryPatch, type CategoryQuery } from '../domain/category';
// Explicit public projection: never return userId or internal account data.
const select = { id: true, clientId: true, name: true, parentId: true, groupId: true, colorToken: true, iconToken: true,
  isSystem: true, archivedAt: true, version: true, createdAt: true, updatedAt: true } satisfies Prisma.CategorySelect;
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
  initialize(userId: string) {
    return this.write(userId, async tx => {
      const owner = await tx.user.findUniqueOrThrow({ where: { id: userId }, select: { categoriesInitializedAt: true } });
      if (owner.categoriesInitializedAt) return;
      await tx.category.createMany({ data: DEFAULT_CATEGORIES.map(([name, iconToken]) => ({ userId, clientId: randomUUID(), name, iconToken, isSystem: true })) });
      await tx.user.update({ where: { id: userId }, data: { categoriesInitializedAt: new Date() } });
    });
  }
  create(userId: string, input: CategoryInput) {
    return this.write(userId, async tx => {
      const existing = await tx.category.findUnique({ where: { userId_clientId: { userId, clientId: input.clientId } }, select });
      if (existing) {
        if (existing.isSystem || (Object.keys(input) as (keyof CategoryInput)[]).some(key => existing[key] !== input[key])) throw new CategoryError('CATEGORY_CONFLICT');
        return { category: existing, created: false };
      }
      assertParent(undefined, input.parentId, await tx.category.findMany({ where: { userId }, select }), true);
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
      assertParent(id, patch.parentId === undefined ? current.parentId : patch.parentId, tree, !archived);
      const { version: _version, archived: _archived, ...fields } = patch;
      return tx.category.update({ where: { id, userId, version: patch.version }, data: { ...fields,
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
