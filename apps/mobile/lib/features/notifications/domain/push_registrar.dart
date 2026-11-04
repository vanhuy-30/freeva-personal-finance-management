import 'package:dartz/dartz.dart';

import '../../auth/domain/auth_repository.dart';

/// Server side of FCM registration (`PUT/DELETE /push-tokens`, one token per session).
abstract class PushTokenRepository {
  Future<Either<AuthFailure, Unit>> put(String token, String platform);
  Future<Either<AuthFailure, Unit>> remove();
}

/// Device side of FCM. Turns itself off when Firebase is not configured for this build.
abstract class PushRegistrar {
  /// Registers the current FCM token with the server. Asks for notification
  /// permission only when [requestPermission] is true (user turned a kind on);
  /// otherwise registers only if permission was already granted.
  Future<void> sync({bool requestPermission = false});

  /// Drops the device token after sign-out so a stale token stops receiving.
  Future<void> clear();

  /// API `kind` of each push the user taps: first the one that launched the
  /// app (if any), then those tapped while it runs. Empty without Firebase.
  Stream<String> openedKinds();
}

/// Screen a tapped notification opens, or null to just open the app.
/// `daily_log` goes straight to recording an expense (BE-P3-006).
String? routeForOpenedKind(String kind) => switch (kind) {
  'daily_log' => '/record?type=expense',
  _ => null,
};
