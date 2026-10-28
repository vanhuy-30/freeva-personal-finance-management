import 'package:dartz/dartz.dart';

import '../../auth/domain/auth_repository.dart';
import 'bill.dart';

abstract class BillRepository {
  Future<Either<AuthFailure, List<Bill>>> list({String? status});
  Future<Either<AuthFailure, Bill>> create(BillDraft draft);
  Future<Either<AuthFailure, Bill>> update(
    Bill bill, {
    String? name,
    String? dueOn,
    BigInt? amountMinor,
    String? amountKind,
    String? currencyCode,
    String? recurringRuleId,
    bool clearRule = false,
  });
  Future<Either<AuthFailure, Unit>> delete(Bill bill);
  Future<Either<AuthFailure, Bill>> pay(Bill bill, String transactionId);
  Future<Either<AuthFailure, Bill>> unpay(Bill bill);
}
