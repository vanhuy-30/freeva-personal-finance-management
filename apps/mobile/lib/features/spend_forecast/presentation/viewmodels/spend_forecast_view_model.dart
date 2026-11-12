import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/feature_flags/feature_flag_service.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../../server_config/domain/server_config.dart';
import '../../domain/spending_forecast.dart';
import '../../domain/spending_forecast_repository.dart';

/// Dự báo chi cuối tháng (MOB-P5-E06): the card on Phân tích (S.2) and the
/// Dự báo chi screen (S.3) share it. With the `forecast` flag off nothing is
/// asked. A failure only hides the card; the rest of Phân tích stays.
abstract class SpendForecastViewModel extends ChangeNotifier {
  /// Null when off, failed, or not loaded yet.
  SpendingForecast? get forecast;

  /// Currency of every amount; null until loaded.
  String? get currencyCode;

  /// The month the forecast is for.
  SpendForecastPeriod? get period;

  /// Whether one answer (possibly empty) has arrived.
  bool get loaded;
  bool get loading;

  /// Last load error; cleared by the next success.
  AuthFailure? get failure;

  /// Fetches again. Later calls win over earlier ones still running.
  Future<void> load();
}

@LazySingleton(as: SpendForecastViewModel)
class DefaultSpendForecastViewModel extends SpendForecastViewModel {
  DefaultSpendForecastViewModel(this._repository, this._flags, this._auth) {
    _stage = _auth.stage;
    _auth.addListener(_authChanged);
  }

  final SpendingForecastRepository _repository;
  final FeatureFlagService _flags;
  final AuthViewModel _auth;
  late AuthStage _stage;
  int _seq = 0;
  SpendingForecastResult _result = SpendingForecastResult.none;

  @override
  SpendingForecast? get forecast => _result.forecast;
  @override
  String? get currencyCode => _result.currencyCode;
  @override
  SpendForecastPeriod? get period => _result.period;
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
    _result = SpendingForecastResult.none;
    loaded = false;
    loading = false;
    failure = null;
    notifyListeners();
  }

  @override
  Future<void> load() async {
    final seq = ++_seq;
    if (!_flags.isEnabled(FeatureFlags.forecast)) {
      _result = SpendingForecastResult.none;
      loaded = true;
      loading = false;
      failure = null;
      notifyListeners();
      return;
    }
    loading = true;
    notifyListeners();
    final result = await _repository.load();
    if (seq != _seq) return;
    loading = false;
    result.fold(
      (error) {
        if (error.code == AuthError.expired) _auth.sessionExpired();
        failure = error;
        _result = SpendingForecastResult.none;
      },
      (value) {
        failure = null;
        _result = value;
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
