import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import { resolvePeriod } from '../../reports/domain/report';
import {
  BudgetError,
  validateCategoryLines,
  validateLimit,
  type BudgetRecord,
  type CategoryRef,
  type ExpenseRow,
} from '../domain/budget';
import type {
  BudgetCurrentQuery,
  BudgetDeleteInput,
  BudgetPutInput,
  BudgetRepository,
  BudgetSummarySource,
} from '../domain/budget.repository';

@Injectable()
export class PrismaBudgetRepository implements BudgetRepository {
  constructor(private readonly prisma: PrismaService) {}

  async current(userId: string, query: BudgetCurrentQuery = {}): Promise<BudgetSummarySource> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { timezone: true, fiscalMonthStartDay: true },
    });
    if (!user) throw new BudgetError('VALIDATION_ERROR');
    const period = resolvePeriod(
      { period: 'month', on: query.on },
      { timezone: user.timezone, fiscalMonthStartDay: user.fiscalMonthStartDay },
    );
    const periodFrom = new Date(period.from);
    const preferDefault = query.applyTo === 'default';
    const [monthRow, defaultRow, expenses, categories] = await Promise.all([
      preferDefault
        ? Promise.resolve(null)
        : this.prisma.budgetMonth.findUnique({
            where: { userId_periodFrom: { userId, periodFrom } },
            include: { categories: { orderBy: [{ categoryId: 'asc' }] } },
          }),
      this.prisma.budget.findUnique({
        where: { userId },
        include: { categories: { orderBy: [{ categoryId: 'asc' }] } },
      }),
      this.prisma.transaction.findMany({
        where: {
          userId,
          type: 'expense',
          deletedAt: null,
          occurredOn: { gte: new Date(period.from), lte: new Date(period.to) },
        },
        select: {
          type: true,
          amountMinor: true,
          currencyCode: true,
          categoryId: true,
          deletedAt: true,
        },
      }),
      this.prisma.category.findMany({
        where: { userId },
        select: { id: true, parentId: true, kind: true, archivedAt: true },
      }),
    ]);
    const budget = preferDefault
      ? defaultRow
        ? mapDefault(defaultRow)
        : null
      : monthRow
        ? mapMonth(monthRow)
        : defaultRow
          ? mapDefault(defaultRow)
          : null;
    return {
      budget,
      expenses: expenses as ExpenseRow[],
      categories: categories as CategoryRef[],
      period,
    };
  }

  async put(userId: string, input: BudgetPutInput): Promise<BudgetRecord> {
    validateLimit(input.limitMinor);
    for (const line of input.categories) validateLimit(line.limitMinor);

    return this.prisma.$transaction(async tx => {
      const user = await tx.user.findUnique({
        where: { id: userId },
        select: { defaultCurrencyCode: true, timezone: true, fiscalMonthStartDay: true },
      });
      if (!user) throw new BudgetError('VALIDATION_ERROR');

      const categories = await tx.category.findMany({
        where: { userId },
        select: { id: true, parentId: true, kind: true, archivedAt: true },
      });
      validateCategoryLines(input.categories, categories as CategoryRef[]);

      if (input.applyTo === 'month') {
        const period = resolvePeriod(
          { period: 'month', on: input.on },
          { timezone: user.timezone, fiscalMonthStartDay: user.fiscalMonthStartDay },
        );
        const periodFrom = new Date(period.from);
        const periodTo = new Date(period.to);
        const existing = await tx.budgetMonth.findUnique({
          where: { userId_periodFrom: { userId, periodFrom } },
        });
        if (existing) {
          if (input.version === undefined || input.version !== existing.version) {
            throw new BudgetError('BUDGET_CONFLICT');
          }
          await tx.budgetMonthCategory.deleteMany({ where: { monthId: existing.id } });
          const updated = await tx.budgetMonth.update({
            where: { id: existing.id },
            data: {
              periodTo,
              currencyCode: user.defaultCurrencyCode,
              limitMinor: input.limitMinor,
              alertThresholds: input.alertThresholds,
              version: { increment: 1 },
              categories: {
                create: input.categories.map(line => ({
                  categoryId: line.categoryId,
                  limitMinor: line.limitMinor,
                })),
              },
            },
            include: { categories: { orderBy: [{ categoryId: 'asc' }] } },
          });
          return mapMonth(updated);
        }
        if (input.version !== undefined) throw new BudgetError('BUDGET_CONFLICT');
        const created = await tx.budgetMonth.create({
          data: {
            userId,
            periodFrom,
            periodTo,
            currencyCode: user.defaultCurrencyCode,
            limitMinor: input.limitMinor,
            alertThresholds: input.alertThresholds,
            categories: {
              create: input.categories.map(line => ({
                categoryId: line.categoryId,
                limitMinor: line.limitMinor,
              })),
            },
          },
          include: { categories: { orderBy: [{ categoryId: 'asc' }] } },
        });
        return mapMonth(created);
      }

      const existing = await tx.budget.findUnique({ where: { userId } });
      if (existing) {
        if (input.version === undefined || input.version !== existing.version) {
          throw new BudgetError('BUDGET_CONFLICT');
        }
        await tx.budgetCategory.deleteMany({ where: { budgetId: existing.id } });
        const updated = await tx.budget.update({
          where: { id: existing.id },
          data: {
            currencyCode: user.defaultCurrencyCode,
            limitMinor: input.limitMinor,
            alertThresholds: input.alertThresholds,
            version: { increment: 1 },
            categories: {
              create: input.categories.map(line => ({
                categoryId: line.categoryId,
                limitMinor: line.limitMinor,
              })),
            },
          },
          include: { categories: { orderBy: [{ categoryId: 'asc' }] } },
        });
        return mapDefault(updated);
      }

      if (input.version !== undefined) throw new BudgetError('BUDGET_CONFLICT');
      const created = await tx.budget.create({
        data: {
          userId,
          currencyCode: user.defaultCurrencyCode,
          limitMinor: input.limitMinor,
          alertThresholds: input.alertThresholds,
          categories: {
            create: input.categories.map(line => ({
              categoryId: line.categoryId,
              limitMinor: line.limitMinor,
            })),
          },
        },
        include: { categories: { orderBy: [{ categoryId: 'asc' }] } },
      });
      return mapDefault(created);
    });
  }

  async delete(userId: string, input: BudgetDeleteInput): Promise<void> {
    if (input.applyTo === 'month') {
      const user = await this.prisma.user.findUnique({
        where: { id: userId },
        select: { timezone: true, fiscalMonthStartDay: true },
      });
      if (!user) throw new BudgetError('VALIDATION_ERROR');
      const period = resolvePeriod(
        { period: 'month', on: input.on },
        { timezone: user.timezone, fiscalMonthStartDay: user.fiscalMonthStartDay },
      );
      const existing = await this.prisma.budgetMonth.findUnique({
        where: { userId_periodFrom: { userId, periodFrom: new Date(period.from) } },
      });
      if (!existing) throw new BudgetError('BUDGET_NOT_FOUND');
      if (input.version !== undefined && input.version !== existing.version) {
        throw new BudgetError('BUDGET_CONFLICT');
      }
      await this.prisma.budgetMonth.delete({ where: { id: existing.id } });
      return;
    }

    const existing = await this.prisma.budget.findUnique({ where: { userId } });
    if (!existing) throw new BudgetError('BUDGET_NOT_FOUND');
    if (input.version !== undefined && input.version !== existing.version) {
      throw new BudgetError('BUDGET_CONFLICT');
    }
    await this.prisma.budget.delete({ where: { id: existing.id } });
  }
}

type BudgetRow = {
  id: string;
  currencyCode: string;
  limitMinor: bigint;
  alertThresholds: number[];
  version: number;
  createdAt: Date;
  updatedAt: Date;
  categories: Array<{ categoryId: string; limitMinor: bigint }>;
};

function mapDefault(row: BudgetRow): BudgetRecord {
  return {
    id: row.id,
    currencyCode: row.currencyCode,
    limitMinor: row.limitMinor,
    alertThresholds: row.alertThresholds,
    version: row.version,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    categories: row.categories.map(line => ({
      categoryId: line.categoryId,
      limitMinor: line.limitMinor,
    })),
    applyTo: 'default',
    isOverride: false,
  };
}

function mapMonth(row: BudgetRow): BudgetRecord {
  return {
    ...mapDefault(row),
    applyTo: 'month',
    isOverride: true,
  };
}
