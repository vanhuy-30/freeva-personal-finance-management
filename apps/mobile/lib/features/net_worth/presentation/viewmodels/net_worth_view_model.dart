import 'package:flutter/foundation.dart';

import '../../../auth/domain/auth_repository.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../../profile/presentation/viewmodels/profile_view_model.dart';
import '../../../wallets/presentation/viewmodels/wallet_view_model.dart';
import '../../domain/net_worth_history.dart';
import '../../domain/net_worth_use_cases.dart';
import '../../../server_config/domain/app_limits.dart';

/// Loads the net-worth history for one window and tracks the point the user
/// touched. Created per page, not a singleton.
class NetWorthViewModel extends ChangeNotifier {
  NetWorthViewModel(
    this._cases,
    this._auth,
    this._profile,
    this._wallets,
    this._limits,
  ) {
    _stage = _auth.stage;
    _auth.addListener(_authChanged);
  }

  /// Server `netWorth.defaultWindow` (MOB-P5-001).
  NetWorthWindow get defaultWindow =>
      NetWorthWindow.fromValue(_limits.requireLimits.netWorthDefaultWindow);

  final AppLimitsSource _limits;

  final NetWorthUseCases _cases;
  final AuthViewModel _auth;
  final ProfileViewModel _profile;
  final WalletViewModel _wallets;
  late AuthStage _stage;
  int _epoch = 0;
  bool _disposed = false;

  late NetWorthWindow window = defaultWindow;
  NetWorthSeries? data;
  bool busy = false;
  AuthFailure? failure;

  /// Index of the touched point; null shows the latest.
  int? selected;

  String get currency => _profile.saved?.overviewCurrency ?? 'VND';

  int get digits =>
      _wallets.currencies
          .where((item) => item.code == currency)
          .firstOrNull
          ?.minorDigits ??
      (currency == 'VND' ? 0 : 2);

  /// The point the card shows: the touched one, else the latest.
  NetWorthPoint? get shown {
    final series = data;
    if (series == null || series.points.isEmpty) return null;
    final i = selected;
    return i != null && i >= 0 && i < series.points.length
        ? series.points[i]
        : series.latest;
  }

  Future<void> load() async {
    if (_wallets.wallets.isEmpty) await _wallets.load();
    if (_disposed) return;
    await _fetch();
  }

  Future<void> reload() => _fetch();

  Future<void> selectWindow(NetWorthWindow value) async {
    if (value == window || busy) return;
    final before = window;
    window = value;
    await _fetch(onFail: () => window = before);
  }

  void select(int? index) {
    if (selected == index) return;
    selected = index;
    _notify();
  }

  Future<void> _fetch({VoidCallback? onFail}) async {
    final epoch = ++_epoch;
    busy = true;
    failure = null;
    _notify();
    final result = await _cases.load(window, currency: currency);
    if (epoch != _epoch || _disposed) return;
    result.fold(
      (error) {
        failure = error;
        if (data != null) onFail?.call();
      },
      (series) {
        data = series;
        selected = null;
        failure = null;
      },
    );
    busy = false;
    _notify();
  }

  void _authChanged() {
    if (_auth.stage == _stage) return;
    _stage = _auth.stage;
    data = null;
    failure = null;
    busy = false;
    selected = null;
    window = defaultWindow;
    _epoch++;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _auth.removeListener(_authChanged);
    super.dispose();
  }
}
