import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics_event.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../domain/sync_item.dart';
import '../../domain/sync_use_cases.dart';

/// How the last attempt to reach the server went.
enum SyncLink { ok, offline, unavailable }

abstract class SyncViewModel extends ChangeNotifier {
  List<SyncQueueItem> get items;

  /// Changes that need the person (conflict or error), then the ones that
  /// are only waiting to be sent.
  List<SyncQueueItem> get attention;
  List<SyncQueueItem> get waiting;
  SyncLink get link;

  /// Last time the server accepted changes; null until the first time.
  DateTime? get lastSyncedAt;
  bool get syncing;
  bool get schemaMismatch;

  /// A just-synced transaction that looks like an earlier one; the screen asks
  /// once, then calls [dismissDuplicate].
  SyncDuplicate? get duplicate;
  void dismissDuplicate();
  int get appliedEpoch;
  Future<void> enqueue(SyncMutation mutation);
  Future<void> discard(String opId);

  /// Sends a failed change again.
  Future<void> retry(String opId);

  /// Keeps the person's version of a conflict and sends it again.
  Future<void> keepLocal(String opId);
  Future<void> acknowledge({String? clientId, String? serverId});
  Future<void> flush();
  Future<void> clear();
  void onResume();
}

@LazySingleton(as: SyncViewModel)
class DefaultSyncViewModel extends SyncViewModel {
  DefaultSyncViewModel(this._cases, this._auth, this._analytics) {
    _stage = _auth.stage;
    _auth.addListener(_authChanged);
    _bootChecked = _auth.ready && _stage != AuthStage.signedOut;
    if (_stage == AuthStage.unlocked) Future.microtask(flush);
  }

  final SyncUseCases _cases;
  final AuthViewModel _auth;
  final AnalyticsService _analytics;
  late AuthStage _stage;
  bool _bootChecked = false;
  int _applied = 0;

  @override
  List<SyncQueueItem> items = const [];
  @override
  List<SyncQueueItem> get attention => [
    for (final item in items)
      if (item.status != SyncItemStatus.pending) item,
  ];
  @override
  List<SyncQueueItem> get waiting => [
    for (final item in items)
      if (item.status == SyncItemStatus.pending) item,
  ];
  @override
  SyncLink link = SyncLink.ok;
  @override
  DateTime? lastSyncedAt;
  @override
  bool syncing = false;
  @override
  bool schemaMismatch = false;
  @override
  SyncDuplicate? duplicate;
  final List<SyncDuplicate> _duplicates = [];
  @override
  int get appliedEpoch => _applied;

  void _authChanged() {
    // A queue left on disk while signed out (app killed mid sign-out) must not
    // be sent into the next account. Wait until auth has read the session.
    if (!_bootChecked && _auth.ready) {
      _bootChecked = true;
      if (_auth.stage == AuthStage.signedOut) clear();
    }
    if (_auth.stage == _stage) return;
    final previous = _stage;
    _stage = _auth.stage;
    if (_stage == AuthStage.signedOut && previous != AuthStage.signedOut) {
      clear();
      return;
    }
    if (_stage == AuthStage.unlocked) flush();
  }

  void _replaced(List<SyncQueueItem> next) {
    final removed = items.length - next.length;
    items = next;
    if (removed > 0) _applied++;
    notifyListeners();
  }

  @override
  Future<void> enqueue(SyncMutation mutation) async {
    _replaced(await _cases.enqueue(mutation));
  }

  @override
  Future<void> discard(String opId) async {
    items = await _cases.discard(opId);
    notifyListeners();
  }

  @override
  Future<void> retry(String opId) async {
    items = await _cases.retry(opId);
    notifyListeners();
    await flush();
  }

  @override
  void dismissDuplicate() {
    duplicate = _duplicates.isEmpty ? null : _duplicates.removeAt(0);
    notifyListeners();
  }

  @override
  Future<void> keepLocal(String opId) async {
    items = await _cases.keepLocal(opId);
    notifyListeners();
    await flush();
  }

  @override
  Future<void> acknowledge({String? clientId, String? serverId}) async {
    items = await _cases.acknowledge(clientId: clientId, serverId: serverId);
    notifyListeners();
  }

  @override
  Future<void> flush() async {
    if (syncing || _stage != AuthStage.unlocked) return;
    syncing = true;
    notifyListeners();
    final before = items.length;
    final outcome = await _cases.flush();
    items = outcome.items;
    schemaMismatch = outcome.schemaMismatch;
    _duplicates.addAll(outcome.duplicates);
    duplicate ??= _duplicates.isEmpty ? null : _duplicates.removeAt(0);
    lastSyncedAt = outcome.lastSyncedAt ?? lastSyncedAt;
    link = switch (outcome.authError) {
      AuthError.network => SyncLink.offline,
      AuthError.unavailable => SyncLink.unavailable,
      _ => SyncLink.ok,
    };
    if (outcome.syncFailed) _analytics.track(AnalyticsEvent.syncFailed);
    if (outcome.authError == AuthError.expired) _auth.sessionExpired();
    syncing = false;
    if (outcome.items.length < before) _applied++;
    notifyListeners();
  }

  @override
  Future<void> clear() async {
    await _cases.clear();
    items = const [];
    lastSyncedAt = null;
    link = SyncLink.ok;
    schemaMismatch = false;
    duplicate = null;
    _duplicates.clear();
    syncing = false;
    notifyListeners();
  }

  @override
  void onResume() {
    if (_stage == AuthStage.unlocked) flush();
  }

  @override
  void dispose() {
    _auth.removeListener(_authChanged);
    super.dispose();
  }
}
