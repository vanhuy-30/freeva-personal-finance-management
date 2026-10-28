import 'package:dartz/dartz.dart';

import '../../auth/domain/auth_repository.dart';
import 'recurring_rule.dart';

abstract class RecurringRepository {
  Future<Either<AuthFailure, List<RecurringRule>>> list({bool? active});
  Future<Either<AuthFailure, RecurringRule>> create(RecurringDraft draft);
  Future<Either<AuthFailure, RecurringRule>> update(
    RecurringRule rule, {
    String? unit,
    int? interval,
    BigInt? amountMinor,
    String? currencyCode,
    String? accountId,
    String? categoryId,
    bool clearCategory = false,
    String? counterAccountId,
    bool clearCounter = false,
    BigInt? counterAmountMinor,
    String? counterCurrencyCode,
    String? fxRate,
    bool clearFx = false,
    String? startDate,
    String? endDate,
    bool clearEnd = false,
    String? nextExecutionDate,
    bool? active,
  });
  Future<Either<AuthFailure, Unit>> delete(RecurringRule rule);
  Future<Either<AuthFailure, RecurringRunResult>> run();
}
