import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:injectable/injectable.dart';

import '../../auth/domain/session_alert_notifier.dart';
import '../domain/push_registrar.dart';

@LazySingleton(as: PushRegistrar)
class FcmPushRegistrar implements PushRegistrar {
  FcmPushRegistrar(this._tokens, this._permission);

  final PushTokenRepository _tokens;
  final SessionAlertNotifier _permission;
  FirebaseMessaging? _messaging;
  StreamSubscription<String>? _refresh;
  bool _unavailable = false;

  /// Null when this build has no Firebase config (google-services.json / plist).
  Future<FirebaseMessaging?> _ensure() async {
    if (_unavailable) return null;
    final existing = _messaging;
    if (existing != null) return existing;
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      return _messaging = FirebaseMessaging.instance;
    } catch (_) {
      _unavailable = true;
      return null;
    }
  }

  String get _platform => Platform.isIOS ? 'ios' : 'android';

  @override
  Future<void> sync({bool requestPermission = false}) async {
    try {
      var access = await _permission.access();
      if (access != NotificationAccess.granted && requestPermission) {
        access = await _permission.requestAccess();
      }
      if (access != NotificationAccess.granted) return;
      final messaging = await _ensure();
      if (messaging == null) return;
      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return;
      await _tokens.put(token, _platform);
      _refresh ??= messaging.onTokenRefresh.listen(
        (next) => unawaited(_tokens.put(next, _platform)),
        onError: (_) {},
      );
    } catch (_) {
      // Push is best effort; the inbox still works.
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _refresh?.cancel();
      _refresh = null;
      final messaging = await _ensure();
      await messaging?.deleteToken();
    } catch (_) {}
  }
}
