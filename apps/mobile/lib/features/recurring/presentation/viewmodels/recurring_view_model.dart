import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../auth/domain/auth_repository.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../../profile/presentation/viewmodels/profile_view_model.dart';
import '../../../transactions/domain/transaction.dart';
import '../../../transactions/domain/transaction_use_cases.dart';
import '../../../wallets/domain/wallet.dart';
import '../../../wallets/presentation/viewmodels/wallet_view_model.dart';
import '../../domain/recurring_rule.dart';
import '../../domain/recurring_use_cases.dart';

@LazySingleton()
class RecurringViewModel extends ChangeNotifier {
  RecurringViewModel(
    this._cases,
    this._auth,
    this._wallets,
    this._profile,
    this._transactions,
  );

  final RecurringUseCases _cases;
  final AuthViewModel _auth;
  final WalletViewModel _wallets;
  final ProfileViewModel _profile;
  final TransactionUseCases _transactions;
  List<RecurringRule> rules = const [];
  bool loading = false;
  bool loaded = false;
  bool running = false;
  AuthFailure? failure;
  bool _disposed = false;

  /// Bills waiting for "Đã trả" (active remind rules), earliest due first;
  /// paused remind rules follow.
  List<RecurringRule> get due {
    final remind = [
      for (final rule in rules)
        if (rule.isRemind && (rule.active || !rule.isOneOff)) rule,
    ];
    return [
      ...remind.where((rule) => rule.active),
      ...remind.where((rule) => !rule.active),
    ];
  }

  /// Rules that post on their own.
  List<RecurringRule> get automatic => [
    for (final rule in rules)
      if (!rule.isRemind) rule,
  ];

  List<RecurringRule> get _pending => [
    for (final rule in rules)
      if (rule.isRemind && rule.active) rule,
  ];

  /// Currency of the "Cần trả" total: the profile currency when a bill uses
  /// it, else the first bill's.
  String get totalCurrency {
    final main = _profile.saved?.currency ?? 'VND';
    final pending = _pending;
    if (pending.isEmpty || pending.any((rule) => rule.currencyCode == main)) {
      return main;
    }
    return pending.first.currencyCode;
  }

  /// Sum of the pending bills in [totalCurrency] (estimated ones count at
  /// their estimate).
  BigInt get dueTotal => _pending
      .where((rule) => rule.currencyCode == totalCurrency)
      .fold(BigInt.zero, (sum, rule) => sum + rule.amountMinor.abs());

  int get dueCount => _pending.length;

  int digitsOf(String currency) =>
      _wallets.currencies
          .where((item) => item.code == currency)
          .firstOrNull
          ?.minorDigits ??
      (currency == 'VND' ? 0 : 2);

  /// Wallets a bill can be paid from or a rule posts to.
  List<Wallet> get wallets => _wallets.active;

  Future<void> loadWallets() async {
    if (_wallets.wallets.isEmpty) await _wallets.load();
  }

  /// Recent expenses to link as a bill's payment (a pointer, nothing new is
  /// posted); null when they could not be read.
  Future<List<TxLeg>?> recentExpenses() async {
    final result = await _transactions.list(
      const TransactionQuery(
        page: 1,
        pageSize: 30,
        deleted: false,
        type: TransactionType.expense,
      ),
    );
    return result.fold((error) {
      _fail(error);
      return null;
    }, (page) => page.legs);
  }

  /// Today in the profile timezone, `yyyy-MM-dd`.
  String get today => _wallets.today.toIso8601String().substring(0, 10);

  Future<void> load() async {
    if (loading) return;
    loading = true;
    failure = null;
    notifyListeners();
    final result = await _cases.list();
    result.fold(_fail, (value) {
      rules = value;
      loaded = true;
    });
    loading = false;
    _notify();
  }

  /// Posts due occurrences; network errors stay silent for boot/resume.
  Future<void> runQuietly() async {
    if (running || _auth.stage != AuthStage.unlocked) return;
    running = true;
    final result = await _cases.run();
    result.fold((_) {}, (_) {});
    running = false;
  }

  Future<bool> setActive(RecurringRule rule, bool active) async {
    final result = await _cases.update(rule, active: active);
    return result.fold(
      (error) {
        _fail(error);
        _notify();
        return false;
      },
      (saved) {
        failure = null;
        rules = [
          for (final item in rules)
            if (item.id == rule.id) saved else item,
        ];
        _notify();
        return true;
      },
    );
  }

  /// "Đã trả" for one due day. Retrying the same [RecurringConfirm] is safe:
  /// the API answers with the first result (`replayed`).
  Future<RecurringConfirmResult?> confirm(
    RecurringRule rule,
    RecurringConfirm confirm,
  ) async {
    final result = await _cases.confirm(rule, confirm);
    return result.fold(
      (error) {
        _fail(error);
        _notify();
        return null;
      },
      (done) {
        failure = null;
        rules = [
          for (final item in rules)
            if (item.id == rule.id) done.rule else item,
        ]..sort((a, b) => a.nextExecutionDate.compareTo(b.nextExecutionDate));
        _notify();
        return done;
      },
    );
  }

  Future<bool> create(RecurringDraft draft) async {
    final result = await _cases.create(draft);
    return result.fold(
      (error) {
        _fail(error);
        _notify();
        return false;
      },
      (rule) {
        failure = null;
        rules = [...rules, rule]
          ..sort((a, b) => a.nextExecutionDate.compareTo(b.nextExecutionDate));
        _notify();
        return true;
      },
    );
  }

  Future<bool> save(RecurringRule rule, RecurringDraft draft) async {
    final result = await _cases.update(
      rule,
      unit: draft.unit,
      interval: draft.interval,
      amountMinor: draft.amountMinor,
      currencyCode: draft.currencyCode,
      accountId: draft.accountId,
      categoryId: draft.categoryId,
      clearCategory: draft.categoryId == null,
      counterAccountId: draft.counterAccountId,
      clearCounter: draft.counterAccountId == null,
      counterAmountMinor: draft.counterAmountMinor,
      counterCurrencyCode: draft.counterCurrencyCode,
      fxRate: draft.fxRate,
      clearFx: draft.fxRate == null,
      startDate: draft.startDate,
      endDate: draft.endDate,
      clearEnd: draft.endDate == null,
      nextExecutionDate: draft.nextExecutionDate,
      active: draft.active,
      name: draft.name,
      amountKind: draft.amountKind,
      remindDaysBefore: draft.mode == 'remind' ? draft.remindDaysBefore : null,
    );
    return result.fold(
      (error) {
        _fail(error);
        _notify();
        return false;
      },
      (saved) {
        failure = null;
        rules = [
          for (final item in rules)
            if (item.id == rule.id) saved else item,
        ]..sort((a, b) => a.nextExecutionDate.compareTo(b.nextExecutionDate));
        _notify();
        return true;
      },
    );
  }

  Future<bool> delete(RecurringRule rule) async {
    final result = await _cases.delete(rule);
    return result.fold(
      (error) {
        _fail(error);
        _notify();
        return false;
      },
      (_) {
        failure = null;
        rules = [
          for (final item in rules)
            if (item.id != rule.id) item,
        ];
        _notify();
        return true;
      },
    );
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

  void _fail(AuthFailure error) {
    failure = error;
    if (error.code == AuthError.expired) _auth.sessionExpired();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
