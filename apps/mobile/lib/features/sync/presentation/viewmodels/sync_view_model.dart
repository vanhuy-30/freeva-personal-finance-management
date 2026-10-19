import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics_event.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../domain/sync_item.dart';
import '../../domain/sync_use_cases.dart';

abstract class SyncViewModel extends ChangeNotifier {
  List<SyncQueueItem> get items;
  bool get syncing;
  bool get schemaMismatch;
  bool get duplicateHint;
  int get appliedEpoch;
  Future<void> enqueue(SyncMutation mutation);
  Future<void> discard(String opId);
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
    if (_stage == AuthStage.unlocked) Future.microtask(flush);
  }

  final SyncUseCases _cases;
  final AuthViewModel _auth;
  final AnalyticsService _analytics;
  late AuthStage _stage;
  int _applied = 0;

  @override
  List<SyncQueueItem> items = const [];
  @override
  bool syncing = false;
  @override
  bool schemaMismatch = false;
  @override
  bool duplicateHint = false;
  @override
  int get appliedEpoch => _applied;

  void _authChanged() {
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
    duplicateHint = outcome.duplicateHint;
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
    schemaMismatch = false;
    duplicateHint = false;
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
