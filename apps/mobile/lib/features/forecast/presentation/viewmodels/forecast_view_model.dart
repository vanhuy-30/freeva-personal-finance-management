import 'package:flutter/foundation.dart';

import '../../../auth/domain/auth_repository.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../../profile/presentation/viewmodels/profile_view_model.dart';
import '../../../recurring/domain/recurring_calendar.dart';
import '../../../recurring/domain/recurring_rule.dart';
import '../../../recurring/domain/recurring_use_cases.dart';
import '../../../wallets/domain/wallet.dart';
import '../../../wallets/presentation/viewmodels/wallet_view_model.dart';
import '../../domain/balance_forecast.dart';
import '../../domain/forecast_use_cases.dart';
import '../../../server_config/domain/app_limits.dart';

/// Loads the rule-based forecast and applies the user's edits (range, which
/// rules count, the start balance). Created per page, not a singleton.
class ForecastViewModel extends ChangeNotifier {
  ForecastViewModel(
    this._cases,
    this._rules,
    this._auth,
    this._profile,
    this._wallets,
    this._limits,
  ) {
    months = _limits.requireLimits.forecastDefaultMonths;
    _stage = _auth.stage;
    _auth.addListener(_authChanged);
  }

  /// Ranges the screen offers (server `forecast.monthOptions`).
  List<int> get ranges => _limits.requireLimits.forecastMonthOptions;

  final ForecastUseCases _cases;
  final RecurringUseCases _rules;
  final AuthViewModel _auth;
  final ProfileViewModel _profile;
  final WalletViewModel _wallets;
  final AppLimitsSource _limits;
  late AuthStage _stage;
  int _epoch = 0;
  bool _disposed = false;

  late int months;
  Set<String> excluded = const {};
  BigInt? startingOverride;

  BalanceForecast? data;
  List<RecurringRule> rules = const [];
  bool busy = false;
  AuthFailure? failure;

  String get currency => _profile.saved?.currency ?? 'VND';

  int get digits => digitsFor(currency);

  int digitsFor(String code) =>
      _wallets.currencies
          .where((item) => item.code == code)
          .firstOrNull
          ?.minorDigits ??
      (code == 'VND' ? 0 : 2);

  /// Wallets the start balance adds up: not archived, not a credit card, same
  /// currency. Matches the API.
  int get walletCount => _wallets.active
      .where(
        (w) =>
            w.draft.type != WalletType.credit && w.draft.currency == currency,
      )
      .length;

  /// Rules the forecast knows about (counted or switched off), income first,
  /// then by day of the month.
  List<RecurringRule> get rows {
    final known = data;
    if (known == null) return const [];
    final ids = {
      ...known.assumptions.includedRuleIds,
      ...known.assumptions.excludedRuleIds,
    };
    final list = [
      for (final rule in rules)
        if (ids.contains(rule.id)) rule,
    ];
    list.sort((a, b) {
      final kind = (a.type == 'income' ? 0 : 1).compareTo(
        b.type == 'income' ? 0 : 1,
      );
      if (kind != 0) return kind;
      final day = anchorDay(a.startDate).compareTo(anchorDay(b.startDate));
      return day != 0
          ? day
          : a.nextExecutionDate.compareTo(b.nextExecutionDate);
    });
    return list;
  }

  bool counted(RecurringRule rule) => !excluded.contains(rule.id);

  /// Rules in another currency, left out by the API (no FX conversion).
  int get otherCurrencyCount =>
      data?.assumptions.otherCurrencyRuleIds.length ?? 0;

  Future<void> load() async {
    if (_wallets.wallets.isEmpty) await _wallets.load();
    if (_disposed) return;
    final rulesResult = rules.isEmpty ? await _rules.list(active: true) : null;
    if (_disposed) return;
    rulesResult?.fold((_) {}, (list) => rules = list);
    await _fetch();
  }

  Future<void> reload() => _fetch();

  Future<void> selectMonths(int value) async {
    if (value == months || busy) return;
    final before = months;
    months = value;
    await _fetch(onFail: () => months = before);
  }

  Future<void> toggle(RecurringRule rule, {required bool counts}) async {
    if (busy) return;
    final before = excluded;
    excluded = counts
        ? ({...excluded}..remove(rule.id))
        : {...excluded, rule.id};
    await _fetch(onFail: () => excluded = before);
  }

  /// Sets the start balance; null goes back to the wallet total.
  Future<void> setStarting(BigInt? value) async {
    if (busy) return;
    final before = startingOverride;
    startingOverride = value;
    await _fetch(onFail: () => startingOverride = before);
  }

  Future<void> _fetch({VoidCallback? onFail}) async {
    final epoch = ++_epoch;
    busy = true;
    failure = null;
    _notify();
    final result = await _cases.load(
      months: months,
      currencyCode: currency,
      startingBalanceMinor: startingOverride,
      excludeRuleIds: excluded,
    );
    if (epoch != _epoch || _disposed) return;
    result.fold(
      (error) {
        failure = error;
        if (data != null) onFail?.call();
      },
      (forecast) {
        data = forecast;
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
    rules = const [];
    failure = null;
    busy = false;
    excluded = const {};
    startingOverride = null;
    months = _limits.requireLimits.forecastDefaultMonths;
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
