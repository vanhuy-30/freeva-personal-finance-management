import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import 'dart:async';

import '../../../../core/money/quantity.dart';
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

  /// Trades per position id, loaded by the category screen.
  final Map<String, List<InvestmentTrade>> trades = {};

  /// Positions of [kind] in the shown currency, newest first.
  List<Investment> ofKind(InvestmentKind kind) => [
    for (final i in _all.reversed)
      if (i.kind == kind && i.currencyCode == currency) i,
  ];

  Investment? byId(String id) => _all.where((i) => i.id == id).firstOrNull;

  /// Buys of [id], oldest first.
  List<InvestmentTrade> buysOf(String id) => [
    for (final t in trades[id] ?? const <InvestmentTrade>[])
      if (t.side == TradeSide.buy) t,
  ]..sort((a, b) => a.tradedOn.compareTo(b.tradedOn));

  /// What was sold out of the positions of [kind]: quantity (scaled) and
  /// realized profit. Null when nothing was sold.
  ({BigInt quantity, BigInt realized, String? unit})? soldOf(
    InvestmentKind kind,
  ) {
    var quantity = BigInt.zero;
    var realized = BigInt.zero;
    var any = false;
    final units = <String>{};
    for (final i in ofKind(kind)) {
      for (final t in trades[i.id] ?? const <InvestmentTrade>[]) {
        if (t.side != TradeSide.sell) continue;
        any = true;
        quantity += t.quantity;
        realized += t.realizedMinor ?? BigInt.zero;
        units.add(i.unit);
      }
    }
    if (!any) return null;
    return (
      quantity: quantity,
      realized: realized,
      unit: units.length == 1 ? units.first : null,
    );
  }

  Future<void> loadTrades(Iterable<String> ids) async {
    final epoch = _epoch;
    final results = await Future.wait([
      for (final id in ids) _cases.trades(id).then((r) => (id, r)),
    ]);
    if (epoch != _epoch || _disposed) return;
    for (final (id, result) in results) {
      result.fold((_) {}, (list) => trades[id] = list);
    }
    _notify();
  }

  /// Sells part or all of [investment]; true when it went through.
  Future<bool> sell(Investment investment, SellDraft draft) async {
    final result = await _cases.sell(investment, draft);
    return _afterWrite(result, investment.id, walletMoved: true);
  }

  /// Takes the whole deposit back as [amountMinor] into [accountId].
  Future<bool> withdraw(
    Investment deposit, {
    required BigInt amountMinor,
    required String accountId,
    required String tradedOn,
    required String clientId,
  }) async {
    final result = await _cases.sell(
      deposit,
      SellDraft(
        clientId: clientId,
        quantity: quantityOne,
        amountMinor: amountMinor,
        accountId: accountId,
        tradedOn: tradedOn,
      ),
    );
    return _afterWrite(result, deposit.id, walletMoved: true);
  }

  /// Renames or re-dates a position; true when it went through.
  Future<bool> update(
    Investment investment, {
    required String name,
    required String? note,
    required String? maturityDate,
  }) async {
    final result = await _cases.update(
      investment,
      name: name,
      note: note,
      maturityDate: maturityDate,
    );
    return _afterWrite(result, investment.id, walletMoved: false);
  }

  /// Deletes a deposit by removing its only buy; the wallet gets the money
  /// back. True when it went through (the deposit is then gone).
  Future<bool> deleteDeposit(Investment deposit) async {
    if (trades[deposit.id] == null) await loadTrades([deposit.id]);
    final buy = buysOf(deposit.id).firstOrNull;
    if (buy == null || _disposed) return false;
    final result = await _cases.deleteTrade(deposit, buy.id);
    if (_disposed) return false;
    final ok = result.isRight();
    result.fold((e) => failure = e, (_) => failure = null);
    if (!ok) {
      _notify();
      return false;
    }
    trades.remove(deposit.id);
    unawaited(_wallets.load());
    await load();
    return true;
  }

  /// Records a manual price; true when it went through.
  Future<bool> setPrice(
    Investment investment,
    BigInt priceMinor,
    DateTime quotedAt, {
    required String clientId,
  }) async {
    final result = await _cases.addPrice(
      investment,
      clientId: clientId,
      priceMinor: priceMinor,
      quotedAt: quotedAt,
    );
    return _afterWrite(result, investment.id, walletMoved: false);
  }

  Future<bool> _afterWrite(
    Either<AuthFailure, Investment> result,
    String id, {
    required bool walletMoved,
  }) async {
    if (_disposed) return false;
    final ok = result.isRight();
    result.fold((e) => failure = e, (_) => failure = null);
    if (!ok) {
      _notify();
      return false;
    }
    if (walletMoved) unawaited(_wallets.load());
    await load();
    await loadTrades([id]);
    return true;
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
    trades.clear();
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
