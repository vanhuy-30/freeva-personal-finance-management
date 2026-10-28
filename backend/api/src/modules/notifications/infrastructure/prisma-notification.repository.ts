import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import { crossedThresholds, totalSpent, type BudgetRecord } from '../../budgets/domain/budget';
import { resolvePeriod, todayInTimeZone } from '../../reports/domain/report';
import {
  dayBefore,
  defaultPreference,
  NotificationError,
  type NotificationKind,
  type NotificationPreferenceRecord,
  type NotificationRecord,
} from '../domain/notification';
import type {
  CreateNotificationInput,
  EvaluateUserContext,
  NotificationRepository,
  PreferencePatch,
} from '../domain/notification.repository';

function asParams(value: Prisma.JsonValue): Record<string, string | number> {
  if (value === null || typeof value !== 'object' || Array.isArray(value)) return {};
  const out: Record<string, string | number> = {};
  for (const [key, entry] of Object.entries(value)) {
    if (typeof entry === 'string' || typeof entry === 'number') out[key] = entry;
  }
  return out;
}

function mapPrefs(row: {
  budgetEnabled: boolean;
  goalEnabled: boolean;
  debtEnabled: boolean;
  cardEnabled: boolean;
  recurringEnabled: boolean;
  monthReviewEnabled: boolean;
  insightEnabled: boolean;
  quietHoursEnabled: boolean;
  quietStart: string;
  quietEnd: string;
  version: number;
  createdAt: Date;
  updatedAt: Date;
}): NotificationPreferenceRecord {
  return {
    budgetEnabled: row.budgetEnabled,
    goalEnabled: row.goalEnabled,
    debtEnabled: row.debtEnabled,
    cardEnabled: row.cardEnabled,
    recurringEnabled: row.recurringEnabled,
    monthReviewEnabled: row.monthReviewEnabled,
    insightEnabled: row.insightEnabled,
    quietHoursEnabled: row.quietHoursEnabled,
    quietStart: row.quietStart,
    quietEnd: row.quietEnd,
    version: row.version,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  };
}

function mapNotification(row: {
  id: string;
  kind: NotificationKind;
  dedupeKey: string;
  titleKey: string;
  bodyKey: string;
  params: Prisma.JsonValue;
  createdAt: Date;
  readAt: Date | null;
}): NotificationRecord {
  return {
    id: row.id,
    kind: row.kind,
    dedupeKey: row.dedupeKey,
    titleKey: row.titleKey,
    bodyKey: row.bodyKey,
    params: asParams(row.params),
    createdAt: row.createdAt,
    readAt: row.readAt,
  };
}

function dayIso(value: Date): string {
  return value.toISOString().slice(0, 10);
}

@Injectable()
export class PrismaNotificationRepository implements NotificationRepository {
  constructor(private readonly prisma: PrismaService) {}

  async getPreferences(userId: string): Promise<NotificationPreferenceRecord> {
    const row = await this.prisma.notificationPreference.findUnique({ where: { userId } });
    if (row) return mapPrefs(row);
    const now = new Date();
    return { ...defaultPreference(), createdAt: now, updatedAt: now };
  }

  async putPreferences(userId: string, patch: PreferencePatch): Promise<NotificationPreferenceRecord> {
    const current = await this.getPreferences(userId);
    if (patch.version !== undefined && patch.version !== current.version) {
      throw new NotificationError('NOTIFICATION_CONFLICT');
    }
    const data = {
      budgetEnabled: patch.budgetEnabled ?? current.budgetEnabled,
      goalEnabled: patch.goalEnabled ?? current.goalEnabled,
      debtEnabled: patch.debtEnabled ?? current.debtEnabled,
      cardEnabled: patch.cardEnabled ?? current.cardEnabled,
      recurringEnabled: patch.recurringEnabled ?? current.recurringEnabled,
      monthReviewEnabled: patch.monthReviewEnabled ?? current.monthReviewEnabled,
      insightEnabled: patch.insightEnabled ?? current.insightEnabled,
      quietHoursEnabled: patch.quietHoursEnabled ?? current.quietHoursEnabled,
      quietStart: patch.quietStart ?? current.quietStart,
      quietEnd: patch.quietEnd ?? current.quietEnd,
      version: current.version + 1,
    };
    const existing = await this.prisma.notificationPreference.findUnique({ where: { userId } });
    if (!existing) {
      const created = await this.prisma.notificationPreference.create({
        data: { userId, ...data, version: 1 },
      });
      return mapPrefs(created);
    }
    const updated = await this.prisma.notificationPreference.update({
      where: { userId },
      data,
    });
    return mapPrefs(updated);
  }

  async list(userId: string): Promise<NotificationRecord[]> {
    const rows = await this.prisma.inAppNotification.findMany({
      where: { userId },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: 100,
    });
    return rows.map(row => mapNotification({ ...row, kind: row.kind as NotificationKind }));
  }

  async markRead(userId: string, id: string): Promise<NotificationRecord> {
    const row = await this.prisma.inAppNotification.findFirst({ where: { id, userId } });
    if (!row) throw new NotificationError('NOTIFICATION_NOT_FOUND');
    if (row.readAt) return mapNotification({ ...row, kind: row.kind as NotificationKind });
    const updated = await this.prisma.inAppNotification.update({
      where: { id },
      data: { readAt: new Date() },
    });
    return mapNotification({ ...updated, kind: updated.kind as NotificationKind });
  }

  async markAllRead(userId: string): Promise<number> {
    const result = await this.prisma.inAppNotification.updateMany({
      where: { userId, readAt: null },
      data: { readAt: new Date() },
    });
    return result.count;
  }

  async createIfAbsent(input: CreateNotificationInput): Promise<boolean> {
    try {
      await this.prisma.inAppNotification.create({
        data: {
          userId: input.userId,
          kind: input.kind,
          dedupeKey: input.dedupeKey,
          titleKey: input.titleKey,
          bodyKey: input.bodyKey,
          params: input.params as Prisma.InputJsonValue,
        },
      });
      return true;
    } catch (error) {
      if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
        return false;
      }
      throw error;
    }
  }

  async listUsersForEvaluate(): Promise<Array<{ userId: string; timezone: string }>> {
    const users = await this.prisma.user.findMany({
      select: { id: true, timezone: true },
      orderBy: { id: 'asc' },
    });
    return users.map(user => ({ userId: user.id, timezone: user.timezone }));
  }

  async loadEvaluateContext(userId: string, now: Date): Promise<EvaluateUserContext> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, timezone: true, fiscalMonthStartDay: true },
    });
    if (!user) {
      return {
        userId,
        timezone: 'UTC',
        prefs: { ...defaultPreference(), createdAt: now, updatedAt: now },
        periodFrom: null,
        crossedThresholds: [],
        recurringSoon: [],
      };
    }
    const prefs = await this.getPreferences(userId);
    const period = resolvePeriod(
      { period: 'month' },
      { timezone: user.timezone, fiscalMonthStartDay: user.fiscalMonthStartDay },
      now,
    );
    const periodFrom = period.from;
    const periodFromDate = new Date(`${periodFrom}T00:00:00.000Z`);
    const periodToDate = new Date(`${period.to}T00:00:00.000Z`);

    const monthBudget = await this.prisma.budgetMonth.findUnique({
      where: { userId_periodFrom: { userId, periodFrom: periodFromDate } },
      include: { categories: true },
    });
    const defaultBudget = monthBudget
      ? null
      : await this.prisma.budget.findUnique({
          where: { userId },
          include: { categories: true },
        });
    const budgetRow = monthBudget ?? defaultBudget;

    let crossed: number[] = [];
    if (budgetRow) {
      const expenses = await this.prisma.transaction.findMany({
        where: {
          userId,
          deletedAt: null,
          type: 'expense',
          occurredOn: { gte: periodFromDate, lte: periodToDate },
        },
        select: {
          type: true,
          amountMinor: true,
          currencyCode: true,
          categoryId: true,
          deletedAt: true,
        },
      });
      const record: BudgetRecord = {
        id: budgetRow.id,
        currencyCode: budgetRow.currencyCode,
        limitMinor: budgetRow.limitMinor,
        alertThresholds: budgetRow.alertThresholds,
        version: budgetRow.version,
        createdAt: budgetRow.createdAt,
        updatedAt: budgetRow.updatedAt,
        categories: budgetRow.categories.map(line => ({
          categoryId: line.categoryId,
          limitMinor: line.limitMinor,
        })),
        applyTo: monthBudget ? 'month' : 'default',
        isOverride: Boolean(monthBudget),
      };
      const spent = totalSpent(expenses, record.currencyCode);
      crossed = crossedThresholds(spent, record.limitMinor, record.alertThresholds);
    }

    const today = todayInTimeZone(user.timezone, now);
    const rules = await this.prisma.recurringRule.findMany({
      where: { userId, active: true },
      select: { id: true, nextExecutionDate: true },
    });
    const recurringSoon = rules
      .map(rule => ({ id: rule.id, nextExecutionDate: dayIso(rule.nextExecutionDate) }))
      .filter(rule => dayBefore(rule.nextExecutionDate) === today);

    return {
      userId: user.id,
      timezone: user.timezone,
      prefs,
      periodFrom: budgetRow ? periodFrom : null,
      crossedThresholds: crossed,
      recurringSoon,
    };
  }
}
