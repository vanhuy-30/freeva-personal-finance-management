import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/notifications/domain/notification_models.dart';
import 'package:mobile/features/notifications/presentation/viewmodels/notification_view_model.dart';

class FakeNotificationViewModel extends NotificationViewModel {
  FakeNotificationViewModel({NotificationPreferences? preferences})
    : preferences = preferences ??
          NotificationPreferences(
            kinds: [
              for (final kind in NotificationKind.values)
                NotificationKindToggle(
                  kind: kind,
                  enabled: kind == NotificationKind.budget ||
                      kind == NotificationKind.recurring,
                  available: kind == NotificationKind.budget ||
                      kind == NotificationKind.recurring ||
                      kind == NotificationKind.security,
                  managedLocally: kind == NotificationKind.security,
                ),
            ],
            quietHoursEnabled: false,
            quietStart: '22:00',
            quietEnd: '07:00',
            version: 1,
            updatedAt: DateTime.utc(2026, 10, 28),
          );

  @override
  bool busy = false;
  @override
  bool loaded = true;
  @override
  AuthFailure? failure;
  @override
  NotificationPreferences? preferences;
  @override
  List<InboxNotification> items = const [];

  @override
  Future<void> loadPreferences() async {}

  @override
  Future<void> loadInbox() async {}

  @override
  Future<void> refreshInbox() async {}

  @override
  Future<bool> setKindEnabled(NotificationKind kind, bool enabled) async {
    final current = preferences;
    if (current == null) return false;
    preferences = NotificationPreferences(
      kinds: [
        for (final toggle in current.kinds)
          NotificationKindToggle(
            kind: toggle.kind,
            enabled: toggle.kind == kind ? enabled : toggle.enabled,
            available: toggle.available,
            managedLocally: toggle.managedLocally,
          ),
      ],
      quietHoursEnabled: current.quietHoursEnabled,
      quietStart: current.quietStart,
      quietEnd: current.quietEnd,
      version: current.version + 1,
      updatedAt: DateTime.utc(2026, 10, 28),
    );
    notifyListeners();
    return true;
  }

  @override
  Future<bool> setQuietHours({
    required bool enabled,
    String? quietStart,
    String? quietEnd,
  }) async {
    final current = preferences;
    if (current == null) return false;
    preferences = NotificationPreferences(
      kinds: current.kinds,
      quietHoursEnabled: enabled,
      quietStart: quietStart ?? current.quietStart,
      quietEnd: quietEnd ?? current.quietEnd,
      version: current.version + 1,
      updatedAt: DateTime.utc(2026, 10, 28),
    );
    notifyListeners();
    return true;
  }

  @override
  Future<void> markRead(String id) async {}

  @override
  Future<void> markAllRead() async {}

  @override
  Future<void> evaluateQuietly() async {}
}
