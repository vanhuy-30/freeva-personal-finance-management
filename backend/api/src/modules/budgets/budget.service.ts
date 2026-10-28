import { Inject, Injectable } from '@nestjs/common';
import { minor } from '../transactions/domain/transaction';
import {
  BudgetError,
  categorySpent,
  crossedThresholds,
  descendantIds,
  normalizeAlertThresholds,
  progress,
  totalSpent,
  type BudgetRecord,
} from './domain/budget';
import { BUDGET_REPOSITORY, type BudgetRepository } from './domain/budget.repository';
import type { DeleteBudgetDto, PutBudgetDto } from './budget.dto';

function money(value: bigint): string {
  return value.toString();
}

function lineResponse(categoryId: string | null, spent: bigint, limit: bigint) {
  const line = progress(spent, limit);
  return {
    ...(categoryId === null ? {} : { categoryId }),
    limitMinor: money(line.limitMinor),
    spentMinor: money(line.spentMinor),
    remainingMinor: money(line.remainingMinor),
    percentBps: line.percentBps,
    status: line.status,
  };
}

function summaryResponse(record: BudgetRecord, source: Awaited<ReturnType<BudgetRepository['current']>>) {
  const spent = totalSpent(source.expenses, record.currencyCode);
  const overall = progress(spent, record.limitMinor);
  return {
    id: record.id,
    currencyCode: record.currencyCode,
    limitMinor: money(overall.limitMinor),
    spentMinor: money(overall.spentMinor),
    remainingMinor: money(overall.remainingMinor),
    percentBps: overall.percentBps,
    status: overall.status,
    alertThresholds: record.alertThresholds,
    crossedThresholds: crossedThresholds(spent, record.limitMinor, record.alertThresholds),
    categories: record.categories.map(line => {
      const descendants = descendantIds(line.categoryId, source.categories);
      const lineSpent = categorySpent(source.expenses, record.currencyCode, line.categoryId, descendants);
      return lineResponse(line.categoryId, lineSpent, line.limitMinor);
    }),
    period: source.period,
    applyTo: record.applyTo,
    isOverride: record.isOverride,
    version: record.version,
    createdAt: record.createdAt.toISOString(),
    updatedAt: record.updatedAt.toISOString(),
  };
}

@Injectable()
export class BudgetService {
  constructor(@Inject(BUDGET_REPOSITORY) private readonly repository: BudgetRepository) {}

  async current(userId: string, query: { on?: string; applyTo?: 'default' | 'month' } = {}) {
    const source = await this.repository.current(userId, query);
    if (!source.budget) return { budget: null, period: source.period };
    return { budget: summaryResponse(source.budget, source), period: source.period };
  }

  async put(userId: string, dto: PutBudgetDto) {
    const applyTo = dto.applyTo ?? 'default';
    if (applyTo === 'month' && !dto.on) throw new BudgetError('VALIDATION_ERROR');
    const record = await this.repository.put(userId, {
      limitMinor: minor(dto.limitMinor),
      alertThresholds: normalizeAlertThresholds(dto.alertThresholds),
      categories: (dto.categories ?? []).map(line => ({
        categoryId: line.categoryId,
        limitMinor: minor(line.limitMinor),
      })),
      version: dto.version,
      applyTo,
      on: dto.on,
    });
    const source = await this.repository.current(userId, {
      on: applyTo === 'month' ? dto.on : undefined,
      applyTo: applyTo === 'default' ? 'default' : undefined,
    });
    if (!source.budget) throw new BudgetError('BUDGET_NOT_FOUND');
    return summaryResponse(record, source);
  }

  delete(userId: string, query: DeleteBudgetDto) {
    const applyTo = query.applyTo ?? 'default';
    if (applyTo === 'month' && !query.on) throw new BudgetError('VALIDATION_ERROR');
    return this.repository.delete(userId, {
      applyTo,
      version: query.version,
      on: query.on,
    });
  }
}
