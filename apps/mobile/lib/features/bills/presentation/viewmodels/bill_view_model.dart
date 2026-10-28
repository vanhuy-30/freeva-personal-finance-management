import 'dart:math';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../auth/domain/auth_repository.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../../transactions/domain/transaction.dart';
import '../../../transactions/domain/transaction_use_cases.dart';
import '../../domain/bill.dart';
import '../../domain/bill_use_cases.dart';

@LazySingleton()
class BillViewModel extends ChangeNotifier {
  BillViewModel(this._cases, this._transactions, this._auth);

  final BillUseCases _cases;
  final TransactionUseCases _transactions;
  final AuthViewModel _auth;

  List<Bill> bills = const [];
  String? filter;
  bool loading = false;
  bool loaded = false;
  AuthFailure? failure;
  bool _disposed = false;

  Future<void> load({String? status}) async {
    if (loading) return;
    loading = true;
    failure = null;
    filter = status;
    notifyListeners();
    final result = await _cases.list(status: status);
    result.fold(_fail, (value) {
      bills = value;
      loaded = true;
    });
    loading = false;
    _notify();
  }

  Future<bool> create(BillDraft draft) async {
    final result = await _cases.create(draft);
    return result.fold(
      (error) {
        _fail(error);
        _notify();
        return false;
      },
      (bill) {
        failure = null;
        bills = [...bills, bill]..sort((a, b) => a.dueOn.compareTo(b.dueOn));
        _notify();
        return true;
      },
    );
  }

  Future<bool> save(Bill bill, BillDraft draft) async {
    final result = await _cases.update(
      bill,
      name: draft.name,
      dueOn: draft.dueOn,
      amountMinor: draft.amountMinor,
      amountKind: draft.amountKind,
      currencyCode: draft.currencyCode,
      recurringRuleId: draft.recurringRuleId,
      clearRule: draft.recurringRuleId == null,
    );
    return result.fold(
      (error) {
        _fail(error);
        _notify();
        return false;
      },
      (saved) {
        failure = null;
        bills = [
          for (final item in bills)
            if (item.id == bill.id) saved else item,
        ]..sort((a, b) => a.dueOn.compareTo(b.dueOn));
        _notify();
        return true;
      },
    );
  }

  Future<bool> delete(Bill bill) async {
    final result = await _cases.delete(bill);
    return result.fold(
      (error) {
        _fail(error);
        _notify();
        return false;
      },
      (_) {
        failure = null;
        bills = [
          for (final item in bills)
            if (item.id != bill.id) item,
        ];
        _notify();
        return true;
      },
    );
  }

  Future<bool> markPaid(Bill bill, String transactionId) async {
    final result = await _cases.pay(bill, transactionId);
    return result.fold(
      (error) {
        _fail(error);
        _notify();
        return false;
      },
      (saved) {
        failure = null;
        bills = [
          for (final item in bills)
            if (item.id == bill.id) saved else item,
        ];
        _notify();
        return true;
      },
    );
  }

  Future<bool> clearPaid(Bill bill) async {
    final result = await _cases.unpay(bill);
    return result.fold(
      (error) {
        _fail(error);
        _notify();
        return false;
      },
      (saved) {
        failure = null;
        bills = [
          for (final item in bills)
            if (item.id == bill.id) saved else item,
        ];
        _notify();
        return true;
      },
    );
  }

  /// Recent non-deleted transactions to link as payment (pointer only).
  Future<Either<AuthFailure, List<TxLeg>>> recentTransactions() async {
    final result = await _transactions.list(
      const TransactionQuery(page: 1, pageSize: 30, deleted: false),
    );
    return result.fold((error) {
      _fail(error);
      return left(error);
    }, (page) => right(page.legs));
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
