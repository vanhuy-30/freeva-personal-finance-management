import 'dart:math';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../auth/domain/auth_repository.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../../profile/presentation/viewmodels/profile_view_model.dart';
import '../../../wallets/domain/wallet.dart';
import '../../../wallets/presentation/viewmodels/wallet_view_model.dart';
import '../../domain/goal.dart';
import '../../domain/goal_use_cases.dart';
import '../../../../core/money/currency_catalog.dart';

@LazySingleton()
class GoalViewModel extends ChangeNotifier {
  GoalViewModel(this._cases, this._wallets, this._profile, this._auth) {
    _stage = _auth.stage;
    _auth.addListener(_authChanged);
  }

  final GoalUseCases _cases;
  final WalletViewModel _wallets;
  final ProfileViewModel _profile;
  final AuthViewModel _auth;
  late AuthStage _stage;
  int _epoch = 0;
  bool _disposed = false;

  List<Goal> _all = const [];
  bool loading = false;
  bool loaded = false;
  AuthFailure? failure;

  /// Goals still being saved for, oldest first.
  List<Goal> get active => [
    for (final goal in _all)
      if (!goal.archived) goal,
  ];

  List<Goal> get archived => [
    for (final goal in _all)
      if (goal.archived) goal,
  ];

  Goal? byId(String id) => _all.where((goal) => goal.id == id).firstOrNull;

  /// Currency of the totals: the profile currency when a goal uses it, else
  /// the first goal's.
  String get totalCurrency {
    final main =
        _profile.saved?.currency ?? CurrencyCatalog.current.defaultCode;
    final goals = active;
    if (goals.isEmpty || goals.any((goal) => goal.currencyCode == main)) {
      return main;
    }
    return goals.first.currencyCode;
  }

  List<Goal> get _inTotal => [
    for (final goal in active)
      if (goal.currencyCode == totalCurrency) goal,
  ];

  BigInt get savedTotal =>
      _inTotal.fold(BigInt.zero, (sum, goal) => sum + goal.currentMinor);

  /// What goals with a future date still ask for this month.
  BigInt get neededThisMonth => _inTotal.fold(
    BigInt.zero,
    (sum, goal) => sum + (goal.requiredPerMonthMinor ?? BigInt.zero),
  );

  /// Monthly income from the profile; null when not given or when it is in a
  /// different currency than [currency].
  BigInt? incomeFor(String currency) => _profile.saved?.currency == currency
      ? _profile.saved?.monthlyIncomeMinor
      : null;

  List<Wallet> get wallets => _wallets.active;

  /// Wallets a goal can sit in or take money from: not a credit card.
  List<Wallet> walletsFor(String currency) => [
    for (final wallet in _wallets.active)
      if (wallet.draft.type != WalletType.credit &&
          wallet.draft.currency == currency)
        wallet,
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
    final result = await _cases.list(includeArchived: true);
    if (epoch != _epoch) return;
    result.fold(_fail, (value) {
      _all = value;
      loaded = true;
    });
    loading = false;
    _notify();
  }

  void _replace(Goal goal) {
    _all = [
      for (final item in _all)
        if (item.id == goal.id) goal else item,
    ];
  }

  Future<Goal?> _write(
    Future<Goal?> Function() action, {
    bool append = false,
  }) async {
    final epoch = _epoch;
    final saved = await action();
    if (epoch != _epoch) return null;
    if (saved == null) {
      _notify();
      return null;
    }
    failure = null;
    if (append && byId(saved.id) == null) {
      _all = [..._all, saved];
    } else {
      _replace(saved);
    }
    _notify();
    return saved;
  }

  Goal? _take(Either<AuthFailure, Goal> result) => result.fold((error) {
    _fail(error);
    return null;
  }, (goal) => goal);

  /// The created goal, or null when it could not be saved.
  Future<Goal?> create(GoalDraft draft) =>
      _write(() async => _take(await _cases.create(draft)), append: true);

  /// The updated goal, or null when it could not be saved.
  Future<Goal?> save(
    Goal goal, {
    required String kind,
    required String name,
    required BigInt target,
    String? targetDate,
  }) => _write(
    () async => _take(
      await _cases.update(
        goal,
        kind: kind,
        name: name,
        targetMinor: target,
        targetDate: targetDate,
        clearTargetDate: targetDate == null,
      ),
    ),
  );

  Future<Goal?> contribute(Goal goal, GoalMove move) =>
      _write(() async => _take(await _cases.contribute(goal, move)));

  Future<Goal?> withdraw(Goal goal, GoalMove move) =>
      _write(() async => _take(await _cases.withdraw(goal, move)));

  Future<Goal?> adjust(Goal goal, BigInt currentMinor) =>
      _write(() async => _take(await _cases.adjust(goal, currentMinor)));

  Future<bool> archive(Goal goal) async {
    final result = await _cases.archive(goal);
    return result.fold(
      (error) {
        _fail(error);
        _notify();
        return false;
      },
      (_) {
        failure = null;
        _replace(goal.asArchived());
        _notify();
        return true;
      },
    );
  }

  /// History of one goal, newest first; null when it could not be read.
  Future<List<GoalEntry>?> entries(Goal goal) async {
    final result = await _cases.entries(goal.id);
    return result.fold((error) {
      _fail(error);
      return null;
    }, (items) => items);
  }

  String newClientId() {
    final random = Random.secure();
    final bytes = List.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
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
