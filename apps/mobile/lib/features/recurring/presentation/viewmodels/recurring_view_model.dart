import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../auth/domain/auth_repository.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../domain/recurring_rule.dart';
import '../../domain/recurring_use_cases.dart';

@LazySingleton()
class RecurringViewModel extends ChangeNotifier {
  RecurringViewModel(this._cases, this._auth);

  final RecurringUseCases _cases;
  final AuthViewModel _auth;
  List<RecurringRule> rules = const [];
  bool loading = false;
  bool loaded = false;
  bool running = false;
  AuthFailure? failure;
  bool _disposed = false;

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
