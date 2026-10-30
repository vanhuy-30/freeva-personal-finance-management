import { Inject, Injectable, Logger, Optional } from '@nestjs/common';
import { PUSH_DISPATCHER, type PushDispatcher } from '../push/domain/push-sender';
import {
  assertKindWritable,
  budgetDedupeKey,
  budgetNotifyThresholds,
  CARD_DUE_WINDOW_DAYS,
  CARD_NEAR_LIMIT_THRESHOLD,
  cardDueDedupeKey,
  cardUsageDedupeKey,
  cardUsageThresholds,
  creditOutstanding,
  daysBetween,
  isInQuietHours,
  kindToggles,
  nextDueDateIso,
  NotificationError,
  recurringDedupeKey,
  validateQuietWindow,
  type NotificationPreferenceRecord,
  type NotificationRecord,
} from './domain/notification';
import {
  NOTIFICATION_REPOSITORY,
  type NotificationRepository,
} from './domain/notification.repository';
import type { PutNotificationPreferencesDto } from './notification.dto';

function preferenceResponse(prefs: NotificationPreferenceRecord) {
  return {
    kinds: kindToggles(prefs),
    quietHoursEnabled: prefs.quietHoursEnabled,
    quietStart: prefs.quietStart,
    quietEnd: prefs.quietEnd,
    version: prefs.version,
    updatedAt: prefs.updatedAt.toISOString(),
  };
}

function notificationResponse(row: NotificationRecord) {
  return {
    id: row.id,
    kind: row.kind,
    titleKey: row.titleKey,
    bodyKey: row.bodyKey,
    params: row.params,
    createdAt: row.createdAt.toISOString(),
    readAt: row.readAt ? row.readAt.toISOString() : null,
  };
}

@Injectable()
export class NotificationService {
  private readonly logger = new Logger(NotificationService.name);

  constructor(
    @Inject(NOTIFICATION_REPOSITORY) private readonly repository: NotificationRepository,
    @Optional() @Inject(PUSH_DISPATCHER) private readonly push?: PushDispatcher,
  ) {}

  async getPreferences(userId: string) {
    return preferenceResponse(await this.repository.getPreferences(userId));
  }

  async putPreferences(userId: string, dto: PutNotificationPreferencesDto) {
    if (dto.budgetEnabled !== undefined) assertKindWritable('budget', dto.budgetEnabled);
    if (dto.goalEnabled !== undefined) assertKindWritable('goal', dto.goalEnabled);
    if (dto.debtEnabled !== undefined) assertKindWritable('debt', dto.debtEnabled);
    if (dto.cardEnabled !== undefined) assertKindWritable('card', dto.cardEnabled);
    if (dto.recurringEnabled !== undefined) assertKindWritable('recurring', dto.recurringEnabled);
    if (dto.monthReviewEnabled !== undefined) {
      assertKindWritable('month_review', dto.monthReviewEnabled);
    }
    if (dto.insightEnabled !== undefined) assertKindWritable('insight', dto.insightEnabled);

    const quietStart = dto.quietStart;
    const quietEnd = dto.quietEnd;
    if (quietStart !== undefined || quietEnd !== undefined || dto.quietHoursEnabled === true) {
      const current = await this.repository.getPreferences(userId);
      validateQuietWindow(quietStart ?? current.quietStart, quietEnd ?? current.quietEnd);
    }

    const prefs = await this.repository.putPreferences(userId, {
      budgetEnabled: dto.budgetEnabled,
      goalEnabled: dto.goalEnabled,
      debtEnabled: dto.debtEnabled,
      cardEnabled: dto.cardEnabled,
      recurringEnabled: dto.recurringEnabled,
      monthReviewEnabled: dto.monthReviewEnabled,
      insightEnabled: dto.insightEnabled,
      quietHoursEnabled: dto.quietHoursEnabled,
      quietStart: dto.quietStart,
      quietEnd: dto.quietEnd,
      version: dto.version,
    });
    return preferenceResponse(prefs);
  }

  async list(userId: string) {
    const items = await this.repository.list(userId);
    return { items: items.map(notificationResponse) };
  }

  async markRead(userId: string, id: string) {
    return notificationResponse(await this.repository.markRead(userId, id));
  }

  async markAllRead(userId: string) {
    const updated = await this.repository.markAllRead(userId);
    return { updated };
  }

  async evaluate(userId: string | null, now = new Date()): Promise<{ created: number }> {
    const users =
      userId === null
        ? await this.repository.listUsersForEvaluate()
        : [{ userId, timezone: '' }];
    let created = 0;
    for (const user of users) {
      created += await this.evaluateOne(user.userId, now);
    }
    await this.drainPush(userId, now);
    return { created };
  }

  /** FCM push (BE-P2-015). A push failure must never fail the inbox evaluation. */
  private async drainPush(userId: string | null, now: Date): Promise<void> {
    if (!this.push) return;
    try {
      await this.push.drain(userId, now);
    } catch (error) {
      const code = error instanceof Error ? error.name : 'unknown';
      this.logger.warn({ code }, 'push.drain.failed');
    }
  }

  private async evaluateOne(userId: string, now: Date): Promise<number> {
    const context = await this.repository.loadEvaluateContext(userId, now);
    if (isInQuietHours(context.prefs, context.timezone, now)) return 0;

    let created = 0;
    if (context.prefs.budgetEnabled && context.periodFrom !== null) {
      for (const threshold of budgetNotifyThresholds(context.crossedThresholds)) {
        const ok = await this.repository.createIfAbsent({
          userId,
          kind: 'budget',
          dedupeKey: budgetDedupeKey(context.periodFrom, threshold),
          titleKey: 'budget_threshold',
          bodyKey: 'budget_threshold_body',
          params: { threshold, periodFrom: context.periodFrom },
        });
        if (ok) created += 1;
      }
    }

    if (context.prefs.recurringEnabled) {
      for (const rule of context.recurringSoon) {
        const ok = await this.repository.createIfAbsent({
          userId,
          kind: 'recurring',
          dedupeKey: recurringDedupeKey(rule.id, rule.nextExecutionDate),
          titleKey: 'recurring_soon',
          bodyKey: 'recurring_soon_body',
          params: { executionDate: rule.nextExecutionDate },
        });
        if (ok) created += 1;
      }
    }

    if (context.prefs.cardEnabled) {
      for (const card of context.creditCards) {
        const used = creditOutstanding(card.balanceMinor);
        const due = nextDueDateIso(card.paymentDueDay, context.today);
        if (due !== null && used > 0n) {
          const days = daysBetween(context.today, due);
          if (days >= 0 && days <= CARD_DUE_WINDOW_DAYS) {
            const ok = await this.repository.createIfAbsent({
              userId,
              kind: 'card',
              dedupeKey: cardDueDedupeKey(card.id, due),
              titleKey: 'card_due',
              bodyKey: 'card_due_body',
              params: { days, accountId: card.id },
            });
            if (ok) created += 1;
          }
        }
        if (context.periodFrom !== null) {
          for (const threshold of cardUsageThresholds(used, card.creditLimitMinor)) {
            const near = threshold >= CARD_NEAR_LIMIT_THRESHOLD;
            const ok = await this.repository.createIfAbsent({
              userId,
              kind: 'card',
              dedupeKey: cardUsageDedupeKey(card.id, context.periodFrom, threshold),
              titleKey: near ? 'card_near_limit' : 'card_high_debt',
              bodyKey: near ? 'card_near_limit_body' : 'card_high_debt_body',
              params: { threshold, accountId: card.id },
            });
            if (ok) created += 1;
          }
        }
      }
    }

    return created;
  }
}

export { NotificationError };
