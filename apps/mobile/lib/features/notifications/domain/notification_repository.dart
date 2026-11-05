import 'package:dartz/dartz.dart';

import '../../auth/domain/auth_repository.dart';
import 'notification_models.dart';

abstract class NotificationRepository {
  Future<Either<AuthFailure, NotificationPreferences>> preferences();
  Future<Either<AuthFailure, NotificationPreferences>> putPreferences(
    NotificationPreferencesPatch patch,
  );
  Future<Either<AuthFailure, List<InboxNotification>>> list();
  Future<Either<AuthFailure, InboxNotification>> markRead(String id);
  Future<Either<AuthFailure, int>> markAllRead();
  Future<Either<AuthFailure, int>> evaluate();
}
