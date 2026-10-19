enum NotificationAccess { granted, denied }

abstract class SessionAlertNotifier {
  Future<NotificationAccess> access();
  Future<NotificationAccess> requestAccess();
  Future<void> show({required String title, required String body});
}
