import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import { toAccountExport } from '../domain/account-export';
import { AccountPrivacyError } from '../domain/account-privacy';
import type { AccountRepository } from '../domain/account.repository';

const order = [{ createdAt: 'asc' as const }, { id: 'asc' as const }];
const options = { timeout: 15_000 };
const audit = (userId: string, action: 'user.data_export' | 'user.account_delete') => ({
  actorType: 'user' as const,
  actorId: userId,
  action,
  targetType: 'user',
  targetId: userId,
  outcome: 'success' as const,
});

async function lockUser(tx: Prisma.TransactionClient, userId: string): Promise<boolean> {
  const rows = await tx.$queryRaw<Array<{ id: string }>>`
    SELECT id FROM "User" WHERE id = ${userId}::uuid FOR UPDATE
  `;
  return rows.length > 0;
}

function rateText(rate: { toFixed(digits: number): string }): string {
  return rate.toFixed(8);
}

@Injectable()
export class PrismaAccountRepository implements AccountRepository {
  constructor(private readonly prisma: PrismaService) {}

  exportForUser(userId: string) {
    return this.prisma.$transaction(tx => this.readExport(tx, userId), options);
  }

  deleteAccount(userId: string) {
    return this.prisma.$transaction(tx => this.removeAccount(tx, userId), options);
  }

  private async readExport(tx: Prisma.TransactionClient, userId: string) {
    if (!(await lockUser(tx, userId))) return null;
    const schema = await tx.schemaMeta.findUnique({ where: { id: 1 } });
    if (!schema) throw new AccountPrivacyError('ACCOUNT_UNAVAILABLE');
    const user = await tx.user.findUnique({
      where: { id: userId },
      select: {
        id: true, email: true, displayName: true, locale: true, timezone: true, defaultCurrencyCode: true,
        fiscalMonthStartDay: true, emailVerifiedAt: true, categoriesInitializedAt: true, categoriesSupplementedAt: true,
        createdAt: true, updatedAt: true, oauthIdentities: { select: { provider: true } },
      },
    });
    if (!user) return null;
    const financialAccounts = await tx.financialAccount.findMany({ where: { userId }, orderBy: order });
    const categoryGroups = await tx.categoryGroup.findMany({ where: { userId }, orderBy: order });
    const categories = await tx.category.findMany({ where: { userId }, orderBy: order });
    const tags = await tx.tag.findMany({ where: { userId }, orderBy: order });
    const fxQuotes = await tx.fxQuote.findMany({ where: { userId }, orderBy: order });
    const recurringRules = await tx.recurringRule.findMany({ where: { userId }, orderBy: order });
    const budget = await tx.budget.findUnique({
      where: { userId },
      include: { categories: { orderBy: [{ categoryId: 'asc' as const }] } },
    });
    const budgetMonths = await tx.budgetMonth.findMany({
      where: { userId },
      orderBy: [{ periodFrom: 'asc' }, { id: 'asc' }],
      include: { categories: { orderBy: [{ categoryId: 'asc' as const }] } },
    });
    const transactions = await tx.transaction.findMany({
      where: { userId }, orderBy: order, include: { tags: { select: { tagId: true } } },
    });
    const exportedAt = new Date();
    await tx.auditEvent.create({ data: audit(userId, 'user.data_export') });
    const { oauthIdentities, ...profile } = user;
    return toAccountExport({
      schemaVersion: schema.version,
      exportedAt,
      user: profile,
      oauthProviders: oauthIdentities.map(row => row.provider),
      financialAccounts,
      categoryGroups,
      categories,
      tags,
      fxQuotes: fxQuotes.map(row => ({ ...row, rate: rateText(row.rate) })),
      recurringRules: recurringRules.map(row => ({
        ...row,
        currencyCode: row.currencyCode,
        counterCurrencyCode: row.counterCurrencyCode,
        fxRate: row.fxRate ? rateText(row.fxRate) : null,
      })),
      budget: budget === null ? null : {
        id: budget.id,
        currencyCode: budget.currencyCode,
        limitMinor: budget.limitMinor,
        alertThresholds: budget.alertThresholds,
        version: budget.version,
        createdAt: budget.createdAt,
        updatedAt: budget.updatedAt,
        categories: budget.categories.map(line => ({
          categoryId: line.categoryId,
          limitMinor: line.limitMinor,
        })),
      },
      budgetMonths: budgetMonths.map(row => ({
        id: row.id,
        currencyCode: row.currencyCode,
        limitMinor: row.limitMinor,
        alertThresholds: row.alertThresholds,
        version: row.version,
        periodFrom: row.periodFrom,
        periodTo: row.periodTo,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        categories: row.categories.map(line => ({
          categoryId: line.categoryId,
          limitMinor: line.limitMinor,
        })),
      })),
      transactions: transactions.map(row => ({ ...row, tagIds: row.tags.map(tag => tag.tagId) })),
    });
  }

  private async removeAccount(tx: Prisma.TransactionClient, userId: string): Promise<boolean> {
    if (!(await lockUser(tx, userId))) return false;
    await tx.recurringOccurrence.deleteMany({ where: { rule: { userId } } });
    await tx.recurringRule.deleteMany({ where: { userId } });
    await tx.budgetMonth.deleteMany({ where: { userId } });
    await tx.budget.deleteMany({ where: { userId } });
    await tx.transactionTag.deleteMany({ where: { transaction: { userId } } });
    await tx.transaction.deleteMany({ where: { userId } });
    await tx.category.updateMany({ where: { userId }, data: { parentId: null, groupId: null } });
    await tx.category.deleteMany({ where: { userId } });
    await tx.categoryGroup.deleteMany({ where: { userId } });
    await tx.tag.deleteMany({ where: { userId } });
    await tx.financialAccount.deleteMany({ where: { userId } });
    await tx.fxQuote.deleteMany({ where: { userId } });
    await tx.auditEvent.create({ data: audit(userId, 'user.account_delete') });
    await tx.user.delete({ where: { id: userId } });
    return true;
  }
}
