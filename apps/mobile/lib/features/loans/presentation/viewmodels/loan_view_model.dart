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
import '../../domain/loan.dart';
import '../../domain/loan_use_cases.dart';

/// Khoản vay tab of "Vay và nợ": loans with their totals and plans.
@LazySingleton()
class LoanViewModel extends ChangeNotifier {
  LoanViewModel(this._cases, this._wallets, this._profile, this._auth) {
    _stage = _auth.stage;
    _auth.addListener(_authChanged);
  }

  final LoanUseCases _cases;
  final WalletViewModel _wallets;
  final ProfileViewModel _profile;
  final AuthViewModel _auth;
  late AuthStage _stage;
  int _epoch = 0;
  bool _disposed = false;

  List<Loan> _all = const [];
  List<LoanTotal> _totals = const [];
  final Map<String, List<LoanScheduleRow>> _schedules = {};
  final Set<String> _fetching = {};
  bool loading = false;
  bool loaded = false;
  AuthFailure? failure;

  /// Loans not archived, in the order they were added.
  List<Loan> get loans => _all;
  bool get isEmpty => _all.isEmpty;

  /// Loans still being paid.
  int get openCount => _all.where((l) => !l.paidOff).length;

  Loan? byId(String id) => _all.where((l) => l.id == id).firstOrNull;

  /// Plan of one loan once loaded (`schedule`); null before.
  List<LoanScheduleRow>? scheduleOf(String id) => _schedules[id];

  String get totalCurrency {
    final main = _profile.saved?.currency ?? 'VND';
    if (_totals.isEmpty || _totals.any((t) => t.currencyCode == main)) {
      return main;
    }
    return _totals.first.currencyCode;
  }

  LoanTotal? get total =>
      _totals.where((t) => t.currencyCode == totalCurrency).firstOrNull;

  List<Wallet> get wallets => _wallets.active;

  Wallet? wallet(String? id) =>
      id == null ? null : _wallets.wallets.where((w) => w.id == id).firstOrNull;

  List<Wallet> walletsFor(String currency) => [
    for (final w in _wallets.active)
      if (w.draft.currency == currency) w,
  ];

  String get profileCurrency => _profile.saved?.currency ?? 'VND';

  int digitsOf(String currency) =>
      _wallets.currencies
          .where((item) => item.code == currency)
          .firstOrNull
          ?.minorDigits ??
      (currency == 'VND' ? 0 : 2);

  String get today => _wallets.today.toIso8601String().substring(0, 10);

  void _authChanged() {
    if (_auth.stage == _stage) return;
    _stage = _auth.stage;
    _epoch++;
    _all = const [];
    _totals = const [];
    _schedules.clear();
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
    final list = results[0] as Either<AuthFailure, List<Loan>>;
    final totals = results[1] as Either<AuthFailure, List<LoanTotal>>;
    list.fold(_fail, (value) {
      _all = value;
      loaded = true;
    });
    totals.fold((_) {}, (value) => _totals = value);
    loading = false;
    _notify();
  }

  /// Loads (or reloads) the plan of [loan]; false when it could not be read.
  Future<bool> loadSchedule(Loan loan) async {
    if (!_fetching.add(loan.id)) return false;
    final epoch = _epoch;
    final result = await _cases.schedule(loan.id);
    _fetching.remove(loan.id);
    if (epoch != _epoch) return false;
    final ok = result.fold(
      (error) {
        _fail(error);
        return false;
      },
      (rows) {
        _schedules[loan.id] = rows;
        return true;
      },
    );
    _notify();
    return ok;
  }

  Future<Loan?> _write(
    Future<Either<AuthFailure, Loan>> Function() action, {
    bool money = false,
  }) async {
    final epoch = _epoch;
    final result = await action();
    if (epoch != _epoch) return null;
    final saved = result.fold((error) {
      _fail(error);
      return null;
    }, (loan) => loan);
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
    _schedules.remove(saved.id);
    final totals = await _cases.totals();
    totals.fold((_) {}, (value) => _totals = value);
    if (money) unawaited(_wallets.load());
    if (epoch != _epoch) return null;
    _notify();
    return saved;
  }

  Future<Loan?> create(LoanDraft draft) => _write(() => _cases.create(draft));

  /// Saves the editable fields, then the remaining debt through `adjust`
  /// when it changed. Null when either step failed.
  Future<Loan?> save(
    Loan loan, {
    required LoanKind kind,
    required String name,
    required int interestRateBps,
    required BigInt? installmentMinor,
    required LoanFrequency frequency,
    required String? endDate,
    required String? nextDueDate,
    required String? accountId,
    required BigInt outstandingMinor,
  }) async {
    final saved = await _write(
      () => _cases.update(
        loan,
        kind: kind,
        name: name,
        interestRateBps: interestRateBps,
        installmentMinor: installmentMinor,
        frequency: frequency,
        endDate: endDate,
        nextDueDate: nextDueDate,
        accountId: accountId,
      ),
    );
    if (saved == null || saved.outstandingMinor == outstandingMinor) {
      return saved;
    }
    return _write(() => _cases.adjust(saved, outstandingMinor));
  }

  Future<Loan?> pay(Loan loan, LoanPayment payment) =>
      _write(() => _cases.pay(loan, payment), money: true);

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
