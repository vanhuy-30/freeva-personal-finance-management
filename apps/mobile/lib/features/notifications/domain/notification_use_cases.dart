import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/domain/auth_repository.dart';
import 'notification_models.dart';
import 'notification_repository.dart';

abstract class NotificationUseCases {
  Future<Either<AuthFailure, NotificationPreferences>> preferences();
  Future<Either<AuthFailure, NotificationPreferences>> putPreferences(
    NotificationPreferencesPatch patch,
  );
  Future<Either<AuthFailure, List<InboxNotification>>> list();
  Future<Either<AuthFailure, InboxNotification>> markRead(String id);
  Future<Either<AuthFailure, int>> markAllRead();
  Future<Either<AuthFailure, int>> evaluate();

  /// True when local OS alerts should be suppressed (profile timezone).
  Future<bool> suppressLocalAlerts(String timeZone, {DateTime? now});
}

@LazySingleton(as: NotificationUseCases)
class DefaultNotificationUseCases implements NotificationUseCases {
  DefaultNotificationUseCases(this._repository);

  final NotificationRepository _repository;

  AuthFailure? _validateQuiet(NotificationPreferencesPatch patch) {
    final start = patch.quietStart;
    final end = patch.quietEnd;
    if (start != null && !isValidHm(start)) {
      return const AuthFailure(AuthError.invalidInput);
    }
    if (end != null && !isValidHm(end)) {
      return const AuthFailure(AuthError.invalidInput);
    }
    if (start != null && end != null && start == end) {
      return const AuthFailure(AuthError.invalidInput);
    }
    return null;
  }

  @override
  Future<Either<AuthFailure, NotificationPreferences>> preferences() =>
      _repository.preferences();

  @override
  Future<Either<AuthFailure, NotificationPreferences>> putPreferences(
    NotificationPreferencesPatch patch,
  ) {
    final error = _validateQuiet(patch);
    if (error != null) return Future.value(left(error));
    return _repository.putPreferences(patch);
  }

  @override
  Future<Either<AuthFailure, List<InboxNotification>>> list() =>
      _repository.list();

  @override
  Future<Either<AuthFailure, InboxNotification>> markRead(String id) =>
      _repository.markRead(id);

  @override
  Future<Either<AuthFailure, int>> markAllRead() => _repository.markAllRead();

  @override
  Future<Either<AuthFailure, int>> evaluate() => _repository.evaluate();

  @override
  Future<bool> suppressLocalAlerts(String timeZone, {DateTime? now}) async {
    final result = await _repository.preferences();
    return result.fold(
      (_) => false,
      (prefs) => isInQuietHours(
        enabled: prefs.quietHoursEnabled,
        quietStart: prefs.quietStart,
        quietEnd: prefs.quietEnd,
        timeZone: timeZone,
        now: now,
      ),
    );
  }
}
