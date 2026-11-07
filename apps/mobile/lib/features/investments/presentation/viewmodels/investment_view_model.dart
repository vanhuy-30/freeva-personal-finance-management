import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import 'dart:async';

import '../../../auth/domain/auth_repository.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../../net_worth/domain/net_worth_history.dart';
import '../../../profile/presentation/viewmodels/profile_view_model.dart';
import '../../../sync/domain/sync_queue.dart';
import '../../../wallets/domain/wallet.dart';
import '../../../wallets/presentation/viewmodels/wallet_view_model.dart';
import '../../domain/investment.dart';
import '../../domain/investment_use_cases.dart';

/// Đầu tư list: totals, share by category, and the positions behind them.
/// Totals come from `GET /investments/summary`.
@LazySingleton()
class InvestmentViewModel extends ChangeNotifier {
  InvestmentViewModel(this._cases, this._profile, this._wallets, this._auth) {
    _stage = _auth.stage;
    _auth.addListener(_authChanged);
  }

  /// Window of the faint value line on the summary card.
  static const lineWindow = NetWorthWindow.half;

  final InvestmentUseCases _cases;
  final ProfileViewModel _profile;
  final WalletViewModel _wallets;
  final AuthViewModel _auth;
  late AuthStage _stage;
  int _epoch = 0;
  bool _disposed = false;

  List<Investment> _all = const [];
  InvestmentSummary _summary = const InvestmentSummary();
  List<InvestmentValuePoint> line = const [];
  bool loading = false;
  bool loaded = false;
  AuthFailure? failure;

  List<Investment> get all => _all;

  bool get isEmpty => _all.isEmpty;

  /// The profile currency when something is held in it, else the first
  /// currency with investments. No FX.
  String get currency {
    final main = _profile.saved?.overviewCurrency ?? 'VND';
    final totals = _summary.totals;
    if (totals.isEmpty || totals.any((t) => t.currencyCode == main)) {
      return main;
    }
    return totals.first.currencyCode;
  }

  int get digits =>
      _wallets.currencies
          .where((item) => item.code == currency)
          .firstOrNull
          ?.minorDigits ??
      (currency == 'VND' ? 0 : 2);

  InvestmentTotal? get total => _summary.totalOf(currency);

  List<InvestmentTotal> get kinds => _summary.kindsOf(currency);

  /// Names of the positions of [kind] in [currency], newest first.
  List<String> names(InvestmentKind kind) => [
    for (final i in _all.reversed)
      if (i.kind == kind && i.currencyCode == currency) i.name,
  ];

  /// Makes sure the wallet list is there before the editor shows it.
  Future<void> loadWallets() async {
    if (_wallets.wallets.isEmpty) await _wallets.load();
  }

  /// Wallets a buy can take money from.
  List<Wallet> get wallets => _wallets.active;

  int digitsOf(String code) =>
      _wallets.currencies
          .where((item) => item.code == code)
          .firstOrNull
          ?.minorDigits ??
      (code == 'VND' ? 0 : 2);

  String get today => _wallets.today.toIso8601String().substring(0, 10);

  /// Profile currency, for a position that is not tied to a wallet.
  String get profileCurrency => _profile.saved?.overviewCurrency ?? 'VND';

  String newClientId() => newSyncOpId();

  /// Opens a position with its first buy. A buy from a wallet moves wallet
  /// money, so wallets are reloaded; the list reloads either way. Null on
  /// failure with [failure] set.
  Future<Investment?> create(InvestmentDraft draft) async {
    final result = await _cases.create(draft);
    if (_disposed) return null;
    return result.fold(
      (error) {
        failure = error;
        _notify();
        return null;
      },
      (saved) {
        failure = null;
        if (draft.accountId != null) unawaited(_wallets.load());
        unawaited(load());
        return saved;
      },
    );
  }

  /// Whether the faint value line has the two points it needs.
  bool get hasLine => line.length >= 2;

  Future<void> load() async {
    if (loading) return;
    final epoch = _epoch;
    loading = true;
    failure = null;
    _notify();
    if (_wallets.wallets.isEmpty) await _wallets.load();
    final results = await Future.wait([_cases.list(), _cases.summary()]);
    if (epoch != _epoch || _disposed) return;
    final list = results[0] as Either<AuthFailure, List<Investment>>;
    final summary = results[1] as Either<AuthFailure, InvestmentSummary>;
    var ok = true;
    list.fold((e) {
      failure = e;
      ok = false;
    }, (value) => _all = value);
    summary.fold((e) {
      failure ??= e;
      ok = false;
    }, (value) => _summary = value);
    if (ok) {
      loaded = true;
      final history = await _cases.valueLine(lineWindow, currency: currency);
      if (epoch != _epoch || _disposed) return;
      // The line is decoration: a failure just hides it.
      line = history.getOrElse(() => const []);
    }
    loading = false;
    _notify();
  }

  void _authChanged() {
    if (_auth.stage == _stage) return;
    _stage = _auth.stage;
    _epoch++;
    _all = const [];
    _summary = const InvestmentSummary();
    line = const [];
    loaded = false;
    loading = false;
    failure = null;
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
