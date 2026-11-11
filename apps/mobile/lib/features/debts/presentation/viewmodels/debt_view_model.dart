import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../auth/domain/auth_repository.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../../profile/presentation/viewmodels/profile_view_model.dart';
import '../../../sync/domain/sync_queue.dart';
import '../../../wallets/domain/wallet.dart';
import '../../../wallets/presentation/viewmodels/wallet_view_model.dart';
import '../../domain/debt_use_cases.dart';
import '../../domain/personal_debt.dart';
import '../../../../core/money/currency_catalog.dart';

/// Người quen tab of "Vay và nợ": who owes you, whom you owe, and what is
/// settled. Totals come from `GET /personal-debts/summary`.
@LazySingleton()
class DebtViewModel extends ChangeNotifier {
  DebtViewModel(this._cases, this._wallets, this._profile, this._auth) {
    _stage = _auth.stage;
    _auth.addListener(_authChanged);
  }

  final DebtUseCases _cases;
  final WalletViewModel _wallets;
  final ProfileViewModel _profile;
  final AuthViewModel _auth;
  late AuthStage _stage;
  int _epoch = 0;
  bool _disposed = false;

  List<PersonalDebt> _all = const [];
  List<DebtTotal> _totals = const [];
  bool loading = false;
  bool loaded = false;
  AuthFailure? failure;

  List<PersonalDebt> get all => _all;

  /// Open debts, most recently lent or borrowed first (DebtList).
  List<PersonalDebt> _open(DebtDirection direction) => [
    for (final debt in _all)
      if (!debt.settled && debt.direction == direction) debt,
  ]..sort((a, b) => b.occurredOn.compareTo(a.occurredOn));

  List<PersonalDebt> get owedToMe => _open(DebtDirection.lent);
  List<PersonalDebt> get iOwe => _open(DebtDirection.borrowed);

  /// Settled debts, most recently lent or borrowed first.
  List<PersonalDebt> get settled => [
    for (final debt in _all)
      if (debt.settled) debt,
  ]..sort((a, b) => b.occurredOn.compareTo(a.occurredOn));

  int get openCount => _all.where((d) => !d.settled).length;

  bool get isEmpty => _all.isEmpty;

  PersonalDebt? byId(String id) => _all.where((d) => d.id == id).firstOrNull;

  /// Currency of the two totals: the profile currency when a debt uses it,
  /// else the first currency with debts.
  String get totalCurrency {
    final main =
        _profile.saved?.currency ?? CurrencyCatalog.current.defaultCode;
    if (_totals.isEmpty || _totals.any((t) => t.currencyCode == main)) {
      return main;
    }
    return _totals.first.currencyCode;
  }

  DebtTotal? get _total =>
      _totals.where((t) => t.currencyCode == totalCurrency).firstOrNull;

  BigInt get receivable => _total?.receivableMinor ?? BigInt.zero;
  BigInt get payable => _total?.payableMinor ?? BigInt.zero;

  List<Wallet> get wallets => _wallets.active;

  Wallet? wallet(String id) =>
      _wallets.wallets.where((w) => w.id == id).firstOrNull;

  /// Wallets a repayment can use: same currency as the debt.
  List<Wallet> walletsFor(String currency) => [
    for (final w in _wallets.active)
      if (w.draft.currency == currency) w,
  ];

  int digitsOf(String currency) =>
      _wallets.currencies
          .where((item) => item.code == currency)
          .firstOrNull
          ?.minorDigits ??
      CurrencyCatalog.current.digits(currency);

  String get today => _wallets.today.toIso8601String().substring(0, 10);

  void _authChanged() {
    if (_auth.stage == _stage) return;
    _stage = _auth.stage;
    _epoch++;
    _all = const [];
    _totals = const [];
    loaded = false;
    loading = false;
    failure = null;
    _notify();
  }

  void _fail(AuthFailure error) {
    failure = error;
    if (error.code == AuthError.expired) _auth.sessionExpired();
  }

  Future<void> load() async {
    if (loading) return;
    final epoch = _epoch;
    loading = true;
    failure = null;
    _notify();
    if (_wallets.wallets.isEmpty) await _wallets.load();
    final results = await Future.wait([_cases.list(), _cases.totals()]);
    if (epoch != _epoch) return;
    final list = results[0] as Either<AuthFailure, List<PersonalDebt>>;
    final totals = results[1] as Either<AuthFailure, List<DebtTotal>>;
    list.fold(_fail, (value) {
      _all = value;
      loaded = true;
    });
    totals.fold((_) {}, (value) => _totals = value);
    loading = false;
    _notify();
  }

  Future<void> _refreshTotals() async {
    final result = await _cases.totals();
    result.fold((_) {}, (value) => _totals = value);
  }

  Future<PersonalDebt?> _write(
    Future<Either<AuthFailure, PersonalDebt>> Function() action, {
    bool money = true,
  }) async {
    final epoch = _epoch;
    final result = await action();
    if (epoch != _epoch) return null;
    final saved = result.fold((error) {
      _fail(error);
      return null;
    }, (debt) => debt);
    if (saved == null) {
      _notify();
      return null;
    }
    failure = null;
    _all = byId(saved.id) == null
        ? [..._all, saved]
        : [
            for (final item in _all)
              if (item.id == saved.id) saved else item,
          ];
    if (money) {
      await _refreshTotals();
      // A debt moves money in or out of a wallet.
      unawaited(_wallets.load());
    }
    if (epoch != _epoch) return null;
    _notify();
    return saved;
  }

  /// The created debt, or null when it could not be saved.
  Future<PersonalDebt?> create(DebtDraft draft) =>
      _write(() => _cases.create(draft));

  Future<PersonalDebt?> save(
    PersonalDebt debt, {
    required String counterparty,
    required String? dueDate,
    required String? note,
  }) => _write(
    () => _cases.update(
      debt,
      counterparty: counterparty,
      dueDate: dueDate,
      note: note,
    ),
    money: false,
  );

  Future<PersonalDebt?> repay(PersonalDebt debt, DebtRepay repay) =>
      _write(() => _cases.repay(debt, repay));

  /// Repayments of one debt, oldest first; null when they could not be read.
  Future<List<DebtPayment>?> payments(PersonalDebt debt) async {
    final result = await _cases.payments(debt.id);
    return result.fold((error) {
      _fail(error);
      return null;
    }, (items) => items);
  }

  String newClientId() => newSyncOpId();

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
