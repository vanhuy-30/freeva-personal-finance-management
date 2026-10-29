import '../../../core/l10n/generated/app_localizations.dart';
import '../domain/notification_models.dart';

String notificationKindTitle(S s, NotificationKind kind) {
  switch (kind) {
    case NotificationKind.budget:
      return s.notifyBudget;
    case NotificationKind.goal:
      return s.notifyGoal;
    case NotificationKind.debt:
      return s.notifyDebt;
    case NotificationKind.card:
      return s.notifyCard;
    case NotificationKind.recurring:
      return s.notifyRecurring;
    case NotificationKind.monthReview:
      return s.notifyMonthReview;
    case NotificationKind.insight:
      return s.notifyInsight;
    case NotificationKind.security:
      return s.notifySession;
  }
}

String notificationKindSubtitle(S s, NotificationKind kind) {
  switch (kind) {
    case NotificationKind.budget:
      return s.notifyBudgetSub;
    case NotificationKind.goal:
      return s.notifyGoalSub;
    case NotificationKind.debt:
      return s.notifyDebtSub;
    case NotificationKind.card:
      return s.notifyCardSub;
    case NotificationKind.recurring:
      return s.notifyRecurringSub;
    case NotificationKind.monthReview:
      return s.notifyMonthReviewSub;
    case NotificationKind.insight:
      return s.notifyInsightSub;
    case NotificationKind.security:
      return s.notifySessionSubAlways;
  }
}

String inboxTitle(S s, InboxNotification item) {
  switch (item.titleKey) {
    case 'budget_threshold':
      final threshold = item.params['threshold'];
      return s.notifyInboxBudgetTitle('$threshold');
    case 'recurring_soon':
      return s.notifyInboxRecurringTitle;
    case 'card_due':
      return s.notifyInboxCardDueTitle;
    case 'card_high_debt':
      return s.notifyInboxCardHighDebtTitle;
    case 'card_near_limit':
      return s.notifyInboxCardNearLimitTitle;
    default:
      return notificationKindTitle(s, item.kind);
  }
}

String inboxBody(S s, InboxNotification item) {
  switch (item.bodyKey) {
    case 'budget_threshold_body':
      final threshold = item.params['threshold'];
      return s.notifyInboxBudgetBody('$threshold');
    case 'recurring_soon_body':
      final date = item.params['executionDate'];
      return s.notifyInboxRecurringBody('$date');
    case 'card_due_body':
      final days = item.params['days'];
      final count = days is int ? days : int.tryParse('$days') ?? 0;
      return s.notifyInboxCardDueBody(count);
    case 'card_high_debt_body':
      final threshold = item.params['threshold'];
      return s.notifyInboxCardHighDebtBody('$threshold');
    case 'card_near_limit_body':
      final threshold = item.params['threshold'];
      return s.notifyInboxCardNearLimitBody('$threshold');
    default:
      return s.notificationsEmptyBody;
  }
}
