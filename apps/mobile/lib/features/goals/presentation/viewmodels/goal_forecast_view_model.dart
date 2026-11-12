import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/feature_flags/feature_flag_service.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../../server_config/domain/server_config.dart';
import '../../domain/goal_forecast.dart';
import '../../domain/goal_use_cases.dart';

/// "Dự kiến đạt" on one goal's detail (MOB-P5-E06, T.1). One per open
/// detail page. With the `forecast` flag off nothing is asked; a failure
/// only hides the card.
@injectable
class GoalForecastViewModel extends ChangeNotifier {
  GoalForecastViewModel(this._cases, this._flags, this._auth);

  final GoalUseCases _cases;
  final FeatureFlagService _flags;
  final AuthViewModel _auth;
  int _seq = 0;
  bool _disposed = false;

  /// What the card shows: null when off, failed, reached or not loaded.
  GoalForecast? get shown => switch (_forecast) {
    GoalForecastOk() || GoalForecastInsufficient() => _forecast,
    _ => null,
  };
  GoalForecast? _forecast;

  /// Fetches the forecast of [goalId] again; later calls win.
  Future<void> load(String goalId) async {
    final seq = ++_seq;
    if (!_flags.isEnabled(FeatureFlags.forecast)) {
      _set(null);
      return;
    }
    final result = await _cases.forecast(goalId);
    if (seq != _seq || _disposed) return;
    _set(
      result.fold((error) {
        if (error.code == AuthError.expired) _auth.sessionExpired();
        return null;
      }, (value) => value),
    );
  }

  void _set(GoalForecast? value) {
    _forecast = value;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _seq++;
    super.dispose();
  }
}
