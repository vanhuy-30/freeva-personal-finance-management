import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';

import '../domain/session_alert_notifier.dart';

@LazySingleton(as: SessionAlertNotifier)
class LocalSessionAlertNotifier implements SessionAlertNotifier {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const int _id = 1009;

  Future<void> _ensureInit() async {
    if (_ready) return;
    final ok = await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    if (ok == false) return;
    _ready = true;
  }

  @override
  Future<NotificationAccess> access() async {
    try {
      await _ensureInit();
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        final enabled = await android.areNotificationsEnabled();
        return enabled == true
            ? NotificationAccess.granted
            : NotificationAccess.denied;
      }
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios != null) {
        final options = await ios.checkPermissions();
        return options?.isEnabled == true
            ? NotificationAccess.granted
            : NotificationAccess.denied;
      }
    } catch (_) {
      return NotificationAccess.denied;
    }
    return NotificationAccess.denied;
  }

  @override
  Future<NotificationAccess> requestAccess() async {
    try {
      await _ensureInit();
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        return granted == true
            ? NotificationAccess.granted
            : NotificationAccess.denied;
      }
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios != null) {
        final granted = await ios.requestPermissions(
          alert: true,
          badge: false,
          sound: false,
        );
        return granted == true
            ? NotificationAccess.granted
            : NotificationAccess.denied;
      }
    } catch (_) {
      return NotificationAccess.denied;
    }
    return NotificationAccess.denied;
  }

  @override
  Future<void> show({required String title, required String body}) async {
    try {
      await _ensureInit();
      await _plugin.show(
        id: _id,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'freeva.session',
            'Freeva',
            channelDescription: 'Freeva',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: false,
            presentSound: false,
          ),
        ),
      );
    } catch (_) {
      return;
    }
  }
}
