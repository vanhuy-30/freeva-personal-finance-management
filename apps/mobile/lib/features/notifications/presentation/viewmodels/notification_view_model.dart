import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../auth/domain/auth_repository.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../../profile/presentation/viewmodels/profile_view_model.dart';
import '../../domain/notification_models.dart';
import '../../domain/notification_use_cases.dart';

abstract class NotificationViewModel extends ChangeNotifier {
  bool get busy;
  bool get loaded;
  AuthFailure? get failure;
  NotificationPreferences? get preferences;
  List<InboxNotification> get items;
  Future<void> loadPreferences();
  Future<void> loadInbox();
  Future<void> refreshInbox();
  Future<bool> setKindEnabled(NotificationKind kind, bool enabled);
  Future<bool> setQuietHours({
    required bool enabled,
    String? quietStart,
    String? quietEnd,
  });
  Future<void> markRead(String id);
  Future<void> markAllRead();
  Future<void> evaluateQuietly();
}

@LazySingleton(as: NotificationViewModel)
class DefaultNotificationViewModel extends NotificationViewModel {
  DefaultNotificationViewModel(this._cases, this._auth, this._profile) {
    _stage = _auth.stage;
    _auth.addListener(_authChanged);
  }

  final NotificationUseCases _cases;
  final AuthViewModel _auth;
  final ProfileViewModel _profile;
  late AuthStage _stage;
  int _epoch = 0;

  @override
  bool busy = false;
  @override
  bool loaded = false;
  @override
  AuthFailure? failure;
  @override
  NotificationPreferences? preferences;
  @override
  List<InboxNotification> items = const [];

  void _authChanged() {
    if (_auth.stage == _stage) return;
    _stage = _auth.stage;
    if (_stage == AuthStage.signedOut) {
      _epoch += 1;
      preferences = null;
      items = const [];
      loaded = false;
      failure = null;
      busy = false;
      notifyListeners();
    }
  }

  Future<T?> _guard<T>(Future<Either<AuthFailure, T>> Function() run) async {
    final epoch = _epoch;
    busy = true;
    failure = null;
    notifyListeners();
    final result = await run();
    if (epoch != _epoch) return null;
    busy = false;
    return result.fold(
      (error) {
        failure = error;
        notifyListeners();
        return null;
      },
      (value) {
        notifyListeners();
        return value;
      },
    );
  }

  @override
  Future<void> loadPreferences() async {
    final value = await _guard(_cases.preferences);
    if (value != null) {
      preferences = value;
      loaded = true;
    }
  }

  @override
  Future<void> loadInbox() async {
    final value = await _guard(() async {
      await _cases.evaluate();
      return _cases.list();
    });
    if (value != null) items = value;
  }

  @override
  Future<void> refreshInbox() => loadInbox();

  @override
  Future<bool> setKindEnabled(NotificationKind kind, bool enabled) async {
    final current = preferences;
    if (current == null) return false;
    final NotificationPreferencesPatch? patch = switch (kind) {
      NotificationKind.budget => NotificationPreferencesPatch(
          budgetEnabled: enabled,
          version: current.version,
        ),
      NotificationKind.goal => NotificationPreferencesPatch(
          goalEnabled: enabled,
          version: current.version,
        ),
      NotificationKind.debt => NotificationPreferencesPatch(
          debtEnabled: enabled,
          version: current.version,
        ),
      NotificationKind.card => NotificationPreferencesPatch(
          cardEnabled: enabled,
          version: current.version,
        ),
      NotificationKind.recurring => NotificationPreferencesPatch(
          recurringEnabled: enabled,
          version: current.version,
        ),
      NotificationKind.monthReview => NotificationPreferencesPatch(
          monthReviewEnabled: enabled,
          version: current.version,
        ),
      NotificationKind.insight => NotificationPreferencesPatch(
          insightEnabled: enabled,
          version: current.version,
        ),
      NotificationKind.security => null,
    };
    if (patch == null) return false;
    final value = await _guard(() => _cases.putPreferences(patch));
    if (value == null) return false;
    preferences = value;
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
    final value = await _guard(
      () => _cases.putPreferences(
        NotificationPreferencesPatch(
          quietHoursEnabled: enabled,
          quietStart: quietStart,
          quietEnd: quietEnd,
          version: current.version,
        ),
      ),
    );
    if (value == null) return false;
    preferences = value;
    return true;
  }

  @override
  Future<void> markRead(String id) async {
    final value = await _guard(() => _cases.markRead(id));
    if (value == null) return;
    items = [
      for (final item in items)
        if (item.id == id) value else item,
    ];
  }

  @override
  Future<void> markAllRead() async {
    final updated = await _guard(_cases.markAllRead);
    if (updated == null) return;
    final stamp = DateTime.now().toUtc();
    items = [
      for (final item in items)
        InboxNotification(
          id: item.id,
          kind: item.kind,
          titleKey: item.titleKey,
          bodyKey: item.bodyKey,
          params: item.params,
          createdAt: item.createdAt,
          readAt: item.readAt ?? stamp,
        ),
    ];
  }

  @override
  Future<void> evaluateQuietly() async {
    if (_auth.stage != AuthStage.unlocked) return;
    await _cases.evaluate();
  }

  // Kept for callers that need the profile zone (quiet-hour checks).
  String get timezone => _profile.saved?.timezone ?? 'Asia/Ho_Chi_Minh';
}
