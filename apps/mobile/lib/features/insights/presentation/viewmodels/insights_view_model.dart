import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/feature_flags/feature_flag_service.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../../server_config/domain/server_config.dart';
import '../../domain/insight.dart';
import '../../domain/insights_repository.dart';

/// Điều đáng chú ý (MOB-P5-E04): the first item on Tổng quan (S.1) and the
/// whole list on Phân tích (S.2). Shared by both so the Overview card and the
/// screen agree. With the `insights` flag off nothing is asked. A failure
/// only hides the card; it never touches the rest of the Overview.
abstract class InsightsViewModel extends ChangeNotifier {
  /// Items in the server's order; empty when off, failed or nothing to say.
  List<Insight> get items;

  /// Currency of every amount; null until loaded.
  String? get currencyCode;

  /// The month the items were worked out for.
  InsightPeriod? get period;

  /// Whether one answer (possibly empty) has arrived.
  bool get loaded;
  bool get loading;

  /// Last load error; cleared by the next success.
  AuthFailure? get failure;

  /// The Overview card's item: the first one, or null to hide the card.
  Insight? get first => items.isEmpty ? null : items.first;

  /// Fetches again. Later calls win over earlier ones still running.
  Future<void> load();
}

@LazySingleton(as: InsightsViewModel)
class DefaultInsightsViewModel extends InsightsViewModel {
  DefaultInsightsViewModel(this._repository, this._flags, this._auth) {
    _stage = _auth.stage;
    _auth.addListener(_authChanged);
  }

  final InsightsRepository _repository;
  final FeatureFlagService _flags;
  final AuthViewModel _auth;
  late AuthStage _stage;
  int _seq = 0;
  InsightList _list = InsightList.empty;

  @override
  List<Insight> get items => _list.items;
  @override
  String? get currencyCode => _list.currencyCode;
  @override
  InsightPeriod? get period => _list.period;
  @override
  bool loaded = false;
  @override
  bool loading = false;
  @override
  AuthFailure? failure;

  void _authChanged() {
    if (_stage == _auth.stage) return;
    _stage = _auth.stage;
    // Figures never outlive the session.
    _seq++;
    _list = InsightList.empty;
    loaded = false;
    loading = false;
    failure = null;
    notifyListeners();
  }

  @override
  Future<void> load() async {
    final seq = ++_seq;
    if (!_flags.isEnabled(FeatureFlags.insights)) {
      _list = InsightList.empty;
      loaded = true;
      loading = false;
      failure = null;
      notifyListeners();
      return;
    }
    loading = true;
    notifyListeners();
    final result = await _repository.list();
    if (seq != _seq) return;
    loading = false;
    result.fold(
      (error) {
        if (error.code == AuthError.expired) _auth.sessionExpired();
        failure = error;
        _list = InsightList.empty;
      },
      (value) {
        failure = null;
        _list = value;
        loaded = true;
      },
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _seq++;
    _auth.removeListener(_authChanged);
    super.dispose();
  }
}
