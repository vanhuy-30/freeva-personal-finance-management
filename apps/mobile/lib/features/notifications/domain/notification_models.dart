import 'package:timezone/timezone.dart' as tz;

enum NotificationKind {
  budget,
  goal,
  debt,
  card,
  recurring,
  monthReview,
  insight,
  security,
  dailyLog,
}

NotificationKind? notificationKindFromApi(String value) {
  switch (value) {
    case 'budget':
      return NotificationKind.budget;
    case 'goal':
      return NotificationKind.goal;
    case 'debt':
      return NotificationKind.debt;
    case 'card':
      return NotificationKind.card;
    case 'recurring':
      return NotificationKind.recurring;
    case 'month_review':
      return NotificationKind.monthReview;
    case 'insight':
      return NotificationKind.insight;
    case 'security':
      return NotificationKind.security;
    case 'daily_log':
      return NotificationKind.dailyLog;
    default:
      return null;
  }
}

String notificationKindToApi(NotificationKind kind) {
  switch (kind) {
    case NotificationKind.budget:
      return 'budget';
    case NotificationKind.goal:
      return 'goal';
    case NotificationKind.debt:
      return 'debt';
    case NotificationKind.card:
      return 'card';
    case NotificationKind.recurring:
      return 'recurring';
    case NotificationKind.monthReview:
      return 'month_review';
    case NotificationKind.insight:
      return 'insight';
    case NotificationKind.security:
      return 'security';
    case NotificationKind.dailyLog:
      return 'daily_log';
  }
}

class NotificationKindToggle {
  const NotificationKindToggle({
    required this.kind,
    required this.enabled,
    required this.available,
    required this.managedLocally,
  });

  final NotificationKind kind;
  final bool enabled;
  final bool available;
  final bool managedLocally;
}

class NotificationPreferences {
  const NotificationPreferences({
    required this.kinds,
    required this.dailyLogTime,
    required this.quietHoursEnabled,
    required this.quietStart,
    required this.quietEnd,
    required this.version,
    required this.updatedAt,
  });

  final List<NotificationKindToggle> kinds;

  /// Daily log reminder time, `HH:mm` in the profile timezone.
  final String dailyLogTime;
  final bool quietHoursEnabled;
  final String quietStart;
  final String quietEnd;
  final int version;
  final DateTime updatedAt;

  NotificationKindToggle? toggle(NotificationKind kind) {
    for (final item in kinds) {
      if (item.kind == kind) return item;
    }
    return null;
  }
}

class NotificationPreferencesPatch {
  const NotificationPreferencesPatch({
    this.budgetEnabled,
    this.goalEnabled,
    this.debtEnabled,
    this.cardEnabled,
    this.recurringEnabled,
    this.monthReviewEnabled,
    this.insightEnabled,
    this.dailyLogEnabled,
    this.dailyLogTime,
    this.quietHoursEnabled,
    this.quietStart,
    this.quietEnd,
    this.version,
  });

  final bool? budgetEnabled;
  final bool? goalEnabled;
  final bool? debtEnabled;
  final bool? cardEnabled;
  final bool? recurringEnabled;
  final bool? monthReviewEnabled;
  final bool? insightEnabled;
  final bool? dailyLogEnabled;
  final String? dailyLogTime;
  final bool? quietHoursEnabled;
  final String? quietStart;
  final String? quietEnd;
  final int? version;
}

class InboxNotification {
  const InboxNotification({
    required this.id,
    required this.kind,
    required this.titleKey,
    required this.bodyKey,
    required this.params,
    required this.createdAt,
    required this.readAt,
  });

  final String id;
  final NotificationKind kind;
  final String titleKey;
  final String bodyKey;
  final Map<String, Object> params;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isRead => readAt != null;
}

final _hm = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');

bool isValidHm(String value) => _hm.hasMatch(value);

/// Minute step of the daily reminder wheel.
const dailyLogMinuteStep = 15;

/// [value] (`HH:mm`) snapped to the nearest [dailyLogMinuteStep], as
/// (hour, minute). Falls back to 20:00 (server default) when unreadable.
(int, int) snapDailyLogTime(String value) {
  final minutes = minutesOfDay(value) ?? 20 * 60;
  final snapped =
      ((minutes / dailyLogMinuteStep).round() * dailyLogMinuteStep) % (24 * 60);
  return (snapped ~/ 60, snapped % 60);
}

String formatHm(int hour, int minute) =>
    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

int? minutesOfDay(String value) {
  final match = _hm.firstMatch(value);
  if (match == null) return null;
  return int.parse(match.group(1)!) * 60 + int.parse(match.group(2)!);
}

/// Quiet window in [timeZone]. Overnight windows wrap midnight; end is exclusive.
bool isInQuietHours({
  required bool enabled,
  required String quietStart,
  required String quietEnd,
  required String timeZone,
  DateTime? now,
}) {
  if (!enabled) return false;
  final start = minutesOfDay(quietStart);
  final end = minutesOfDay(quietEnd);
  if (start == null || end == null || start == end) return false;
  try {
    final local = tz.TZDateTime.from(
      (now ?? DateTime.now()).toUtc(),
      tz.getLocation(timeZone),
    );
    final nowM = local.hour * 60 + local.minute;
    if (start < end) return nowM >= start && nowM < end;
    return nowM >= start || nowM < end;
  } catch (_) {
    return false;
  }
}
