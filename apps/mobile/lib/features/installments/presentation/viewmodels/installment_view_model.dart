import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../auth/domain/auth_repository.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../../sync/domain/sync_queue.dart';
import '../../../wallets/domain/credit_card_status.dart';
import '../../../wallets/domain/wallet.dart';
import '../../../wallets/presentation/viewmodels/wallet_view_model.dart';
import '../../domain/card_installment.dart';
import '../../domain/card_installment_use_cases.dart';
import '../../../../core/money/currency_catalog.dart';

/// Installments due on one card: this period, and everything after it.
class _CardDue {
  const _CardDue(this.dueOn, this.thisPeriod, this.later);
  final DateTime dueOn;
  final BigInt thisPeriod;
  final BigInt later;
}

/// Card installment plans (MOB-P3-009): the active plans and "Phải trả kỳ
/// này" of each card, plan details, preview, create and close. Online only.
@LazySingleton()
class InstallmentViewModel extends ChangeNotifier {
  InstallmentViewModel(this._cases, this._wallets, this._auth) {
    _stage = _auth.stage;
    _auth.addListener(_authChanged);
  }

  final CardInstallmentUseCases _cases;
  final WalletViewModel _wallets;
  final AuthViewModel _auth;
  late AuthStage _stage;
  int _epoch = 0;
  bool _disposed = false;

  final Map<String, List<CardInstallment>> _plans = {};
  final Map<String, _CardDue> _due = {};
  final Map<String, CardInstallment> _details = {};
  AuthFailure? failure;

  /// Active plans of a card, oldest first; empty until loaded.
  List<CardInstallment> plansOf(String accountId) =>
      _plans[accountId] ?? const [];

  CardInstallment? detail(String id) => _details[id];

  Wallet? wallet(String id) => _wallets.byId(id);

  DateTime get today => _wallets.today;

  int digitsOf(String currency) =>
      _wallets.currencies
          .where((item) => item.code == currency)
          .firstOrNull
          ?.minorDigits ??
      CurrencyCatalog.current.digits(currency);

  /// "Phải trả kỳ này" of [wallet] once its plans are loaded; null without
  /// active plans or without a due day.
  CardPeriodDue? periodDueOf(Wallet wallet) {
    final due = _due[wallet.id];
    if (due == null || plansOf(wallet.id).isEmpty) return null;
    return CardPeriodDue.of(
      dueOn: due.dueOn,
      debtMinor: CreditCardStatus.of(wallet, today).used,
      laterMinor: due.later,
      installmentMinor: due.thisPeriod,
    );
  }

  void _authChanged() {
    if (_auth.stage == _stage) return;
    _stage = _auth.stage;
    _epoch++;
    _plans.clear();
    _due.clear();
    _details.clear();
    failure = null;
    _notify();
  }

  void _fail(AuthFailure error) {
    failure = error;
    if (error.code == AuthError.expired) _auth.sessionExpired();
  }

  static BigInt _sum(Either<AuthFailure, List<InstallmentDue>> result) =>
      result.fold(
        (_) => BigInt.zero,
        (rows) => rows.fold(BigInt.zero, (sum, r) => sum + r.dueMinor),
      );

  /// Active plans of a credit [wallet] and what falls due this period.
  Future<void> loadCard(Wallet wallet) async {
    if (wallet.draft.type != WalletType.credit) return;
    final epoch = _epoch;
    final id = wallet.id;
    final plans = await _cases.list(accountId: id, active: true);
    if (epoch != _epoch) return;
    final list = plans.fold((error) {
      _fail(error);
      return null;
    }, (value) => value);
    if (list == null) {
      _notify();
      return;
    }
    _plans[id] = list;
    final dueDay = wallet.draft.dueDay;
    final next = nextDueDate(dueDay, today);
    if (list.isEmpty || dueDay == null || next == null) {
      _due.remove(id);
      _notify();
      return;
    }
    final previous = previousDueDate(next, dueDay);
    final results = await Future.wait([
      _cases.due(
        from: isoDay(previous.add(const Duration(days: 1))),
        to: isoDay(next),
        accountId: id,
      ),
      _cases.due(
        from: isoDay(next.add(const Duration(days: 1))),
        to: '2099-12-31',
        accountId: id,
      ),
    ]);
    if (epoch != _epoch) return;
    if (results.any((r) => r.isLeft())) {
      _due.remove(id);
    } else {
      _due[id] = _CardDue(next, _sum(results[0]), _sum(results[1]));
    }
    _notify();
  }

  /// Reads one plan with its schedule; false when it could not be read.
  Future<bool> load(String id) async {
    final epoch = _epoch;
    final result = await _cases.find(id);
    if (epoch != _epoch) return false;
    final ok = result.fold(
      (error) {
        _fail(error);
        return false;
      },
      (plan) {
        failure = null;
        _details[id] = plan;
        return true;
      },
    );
    _notify();
    return ok;
  }

  Future<Either<AuthFailure, InstallmentPreview>> preview(
    InstallmentDraft draft,
  ) => _cases.preview(draft);

  /// Null when the plan could not be made ([failure] says why).
  Future<CardInstallment?> create(
    InstallmentDraft draft, {
    required String clientId,
  }) => _write(() => _cases.create(draft, clientId: clientId));

  Future<CardInstallment?> close(CardInstallment plan) =>
      _write(() => _cases.close(plan));

  Future<CardInstallment?> _write(
    Future<Either<AuthFailure, CardInstallment>> Function() action,
  ) async {
    final epoch = _epoch;
    final result = await action();
    if (epoch != _epoch) return null;
    final saved = result.fold((error) {
      _fail(error);
      return null;
    }, (plan) => plan);
    if (saved != null) {
      failure = null;
      _details[saved.id] = saved;
      final card = wallet(saved.accountId);
      if (card != null) await loadCard(card);
    }
    _notify();
    return saved;
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
