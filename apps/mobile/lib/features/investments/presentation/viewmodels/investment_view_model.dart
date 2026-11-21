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
import '../../../server_config/domain/app_limits.dart';
import '../../../../core/money/currency_catalog.dart';

/// A matured deposit that was paid back to the wallet it came from.
class MaturedPayout {
  const MaturedPayout({
    required this.deposit,
    required this.amountMinor,
    required this.walletName,
  });

  final Investment deposit;

  /// Principal plus interest.
  final BigInt amountMinor;
  final String walletName;
}

/// Đầu tư list: totals, share by category, and the positions behind them.
/// Totals come from `GET /investments/summary`.
@LazySingleton()
class InvestmentViewModel extends ChangeNotifier {
  InvestmentViewModel(
    this._cases,
    this._profile,
    this._wallets,
    this._auth,
    this._limits,
  ) {
    _stage = _auth.stage;
    _auth.addListener(_authChanged);
  }

  /// Window of the faint value line on the summary card (server
  /// `investment.chartDefaultWindow`).
  NetWorthWindow get lineWindow =>
      NetWorthWindow.fromValue(_limits.requireLimits.investmentChartWindow);

  final AppLimitsSource _limits;

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
    final main =
        _profile.saved?.overviewCurrency ?? CurrencyCatalog.current.defaultCode;
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
      CurrencyCatalog.current.digits(currency);

  InvestmentTotal? get total => _summary.totalOf(currency);

  List<InvestmentTotal> get kinds => _summary.kindsOf(currency);

  /// Interest the held deposits in the shown currency pay over their whole
  /// terms; a deposit has no gain or loss, only this.
  BigInt get expectedDepositInterest => _all
      .where((i) => i.isDeposit && i.currencyCode == currency && !i.archived)
      .fold(
        BigInt.zero,
        (sum, i) => sum + (i.interestAtMaturity ?? BigInt.zero),
      );

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
      CurrencyCatalog.current.digits(code);

  String get today => _wallets.today.toIso8601String().substring(0, 10);

  /// Profile currency, for a position that is not tied to a wallet.
  String get profileCurrency =>
      _profile.saved?.overviewCurrency ?? CurrencyCatalog.current.defaultCode;

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

  final Set<String> _settling = {};

  /// Wallet a deposit was paid from when it can take the money back (still
  /// active, same currency); null for a deposit held before the app.
  Wallet? _sourceWallet(Investment deposit) {
    final id = buysOf(deposit.id).firstOrNull?.accountId;
    if (id == null) return null;
    return wallets
        .where((w) => w.id == id && w.draft.currency == deposit.currencyCode)
        .firstOrNull;
  }

  /// Principal plus the interest of the whole term: what a deposit pays at
  /// maturity.
  BigInt maturityPayout(Investment deposit) =>
      deposit.costBasisMinor + (deposit.interestAtMaturity ?? BigInt.zero);

  /// Pays every matured deposit that came from a wallet back into it, and
  /// returns what was paid so the app can tell the user. Run after [load].
  Future<List<MaturedPayout>> settleMatured() async {
    final payouts = <MaturedPayout>[];
    final due = [
      for (final i in _all)
        if (i.maturedOn(today)) i,
    ];
    for (final deposit in due) {
      if (_disposed || !_settling.add(deposit.id)) continue;
      try {
        if (trades[deposit.id] == null) await loadTrades([deposit.id]);
        final wallet = _sourceWallet(deposit);
        if (wallet == null) continue;
        final amount = maturityPayout(deposit);
        final ok = await withdraw(
          deposit,
          amountMinor: amount,
          accountId: wallet.id,
          tradedOn: deposit.maturityDate!,
          clientId: newClientId(),
        );
        if (ok) {
          payouts.add(
            MaturedPayout(
              deposit: deposit,
              amountMinor: amount,
              walletName: wallet.draft.name,
            ),
          );
        }
      } finally {
        _settling.remove(deposit.id);
      }
    }
    return payouts;
  }

  /// Matured deposits held before the app (or whose wallet is gone): the
  /// user decides between a wallet and a new deposit.
  List<Investment> get maturedAwaitingChoice => [
    for (final i in _all)
      if (i.maturedOn(today) &&
          trades[i.id] != null &&
          _sourceWallet(i) == null)
        i,
  ];

  /// Renews a matured deposit: the payout becomes a new deposit of the same
  /// length and rate, held before the app (no wallet moves), and the old one
  /// is removed. True when both went through.
  Future<bool> renewDeposit(Investment deposit) async {
    final start = deposit.startDate;
    final maturity = deposit.maturityDate;
    final rate = deposit.interestRateBps;
    if (start == null || maturity == null || rate == null) return false;
    final from = DateTime.parse('${today}T00:00:00Z');
    final until = from
        .add(Duration(days: depositTermDays(start, maturity)))
        .toIso8601String()
        .substring(0, 10);
    final created = await create(
      InvestmentDraft(
        clientId: newClientId(),
        tradeClientId: newClientId(),
        kind: InvestmentKind.savingsDeposit,
        name: deposit.name,
        currencyCode: deposit.currencyCode,
        unit: deposit.unit,
        quantity: quantityOne,
        tradedOn: today,
        amountMinor: maturityPayout(deposit),
        note: deposit.note,
        interestRateBps: rate,
        startDate: today,
        maturityDate: until,
      ),
    );
    if (created == null) return false;
    // `create` reloads in the background; let it finish so the removal below
    // refreshes the list afterwards.
    while (loading && !_disposed) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    return deleteDeposit(deposit);
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

  InvestmentTrade? tradeById(String id, String tradeId) =>
      (trades[id] ?? const <InvestmentTrade>[])
          .where((t) => t.id == tradeId)
          .firstOrNull;

  /// Changes one buy; true when it went through.
  Future<bool> updateTrade(
    Investment investment,
    String tradeId,
    TradeEdit edit,
  ) async {
    final result = await _cases.updateTrade(investment, tradeId, edit);
    return _afterWrite(result, investment.id, walletMoved: true);
  }

  /// Deletes one buy and refreshes; true when it went through. The position
  /// disappears with its last trade ([byId] is then null).
  Future<bool> deleteBuy(Investment investment, String tradeId) async {
    final result = await _cases.deleteTrade(investment, tradeId);
    if (_disposed) return false;
    final ok = result.isRight();
    result.fold((e) => failure = e, (_) => failure = null);
    if (!ok) {
      _notify();
      return false;
    }
    unawaited(_wallets.load());
    await load();
    if (byId(investment.id) == null) {
      trades.remove(investment.id);
    } else {
      await loadTrades([investment.id]);
    }
    return true;
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
