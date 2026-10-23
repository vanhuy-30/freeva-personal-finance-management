import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import { touchFinancialOwner } from '../../../infrastructure/prisma/financial-owner-lock';
import type { TagRepository } from '../domain/tag.repository';
import { assertTagVersion, TagError, type Tag, type TagInput, type TagPatch, type TagQuery } from '../domain/tag';

const select = {
  id: true, clientId: true, name: true, version: true, createdAt: true, updatedAt: true,
} satisfies Prisma.TagSelect;

@Injectable()
export class PrismaTagRepository implements TagRepository {
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
  private async get(tx: Prisma.TransactionClient, userId: string, id: string): Promise<Tag> {
    const row = await tx.tag.findFirst({ where: { id, userId }, select });
    if (!row) throw new TagError('TAG_NOT_FOUND');
    return row;
  }
  create(userId: string, input: TagInput) {
    return this.write(userId, async tx => {
      const existing = await tx.tag.findUnique({ where: { userId_clientId: { userId, clientId: input.clientId } }, select });
      if (existing) {
        if (existing.name !== input.name) throw new TagError('TAG_CONFLICT');
        return { tag: existing, created: false };
      }
      return { tag: await tx.tag.create({ data: { ...input, userId }, select }), created: true };
    });
  }
  find(userId: string, id: string) { return this.get(this.prisma, userId, id); }
  list(userId: string, query: TagQuery) {
    return this.prisma.$transaction(async tx => {
      const where: Prisma.TagWhereInput = { userId };
      const rows = await tx.tag.findMany({
        where,
        select: { ...select, _count: { select: { transactions: { where: { transaction: { deletedAt: null } } } } } },
        orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
        skip: (query.page - 1) * query.pageSize, take: query.pageSize,
      });
      const items = rows.map(({ _count, ...row }) => ({ ...row, transactionCount: _count.transactions }));
      return { items, total: await tx.tag.count({ where }) };
    }, { isolationLevel: Prisma.TransactionIsolationLevel.RepeatableRead });
  }
  update(userId: string, id: string, patch: TagPatch) {
    return this.write(userId, async tx => {
      const current = await this.get(tx, userId, id);
      assertTagVersion(current.version, patch.version);
      const { version: _version, ...fields } = patch;
      return tx.tag.update({
        where: { id, userId, version: patch.version },
        data: { ...fields, version: { increment: 1 } },
        select,
      });
    });
  }
  delete(userId: string, id: string, version: number) {
    return this.write(userId, async tx => {
      const current = await this.get(tx, userId, id);
      assertTagVersion(current.version, version);
      const links = await tx.transactionTag.findMany({
        where: { tagId: id, transaction: { userId } },
        select: { transactionId: true },
      });
      if (links.length) {
        const transactionIds = [...new Set(links.map(link => link.transactionId))];
        if (await tx.transaction.count({ where: { userId, id: { in: transactionIds }, version: { gte: 2147483647 } } })) {
          throw new TagError('TAG_CONFLICT');
        }
        await tx.transactionTag.deleteMany({ where: { tagId: id, transactionId: { in: transactionIds } } });
        await tx.transaction.updateMany({
          where: { userId, id: { in: transactionIds } },
          data: { version: { increment: 1 }, updatedAt: new Date() },
        });
      }
      await tx.tag.delete({ where: { id, userId, version } });
    });
  }
}
