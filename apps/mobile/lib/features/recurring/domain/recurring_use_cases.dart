import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/domain/auth_repository.dart';
import 'recurring_calendar.dart';
import 'recurring_repository.dart';
import 'recurring_rule.dart';
import '../../server_config/domain/app_limits.dart';

abstract class RecurringUseCases {
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
    String? name,
    String? amountKind,
    int? remindDaysBefore,
  });
  Future<Either<AuthFailure, Unit>> delete(RecurringRule rule);
  Future<Either<AuthFailure, RecurringConfirmResult>> confirm(
    RecurringRule rule,
    RecurringConfirm confirm,
  );
  Future<Either<AuthFailure, RecurringRunResult>> run();
}

@LazySingleton(as: RecurringUseCases)
class DefaultRecurringUseCases implements RecurringUseCases {
  DefaultRecurringUseCases(this._repository, this._limits);
  final RecurringRepository _repository;
  final AppLimitsSource _limits;

  AuthFailure? _validateDraft(RecurringDraft draft) {
    if (!recurringUnits.contains(draft.unit)) {
      return const AuthFailure(AuthError.invalidInput);
    }
    if (draft.interval < 1 || draft.interval > 366) {
      return const AuthFailure(AuthError.invalidInput);
    }
    if (parseCalendarParts(draft.startDate) == null ||
        parseCalendarParts(draft.nextExecutionDate) == null) {
      return const AuthFailure(AuthError.invalidInput);
    }
    if (draft.nextExecutionDate.compareTo(draft.startDate) < 0) {
      return const AuthFailure(AuthError.invalidInput);
    }
    if (draft.endDate != null &&
        (parseCalendarParts(draft.endDate!) == null ||
            draft.endDate!.compareTo(draft.startDate) < 0)) {
      return const AuthFailure(AuthError.invalidInput);
    }
    if (draft.mode != 'auto' && draft.mode != 'remind') {
      return const AuthFailure(AuthError.invalidInput);
    }
    if (draft.remindDaysBefore < 0 ||
        draft.remindDaysBefore > _limits.requireLimits.remindBeforeMax) {
      return const AuthFailure(AuthError.invalidInput);
    }
    if (draft.mode == 'remind') {
      // A bill: one named expense, no counter leg. Wallet and category are
      // optional defaults for the confirm step.
      final name = draft.name?.trim() ?? '';
      if (draft.type != 'expense' ||
          name.isEmpty ||
          name.length > 80 ||
          draft.amountMinor >= BigInt.zero ||
          draft.counterAccountId != null) {
        return const AuthFailure(AuthError.invalidInput);
      }
      return null;
    }
    if (draft.accountId == null) {
      return const AuthFailure(AuthError.invalidInput);
    }
    if (draft.type == 'expense') {
      if (draft.categoryId == null || draft.amountMinor >= BigInt.zero) {
        return const AuthFailure(AuthError.invalidInput);
      }
    } else if (draft.type == 'income') {
      if (draft.amountMinor <= BigInt.zero) {
        return const AuthFailure(AuthError.invalidInput);
      }
    } else if (draft.type == 'transfer') {
      if (draft.categoryId != null ||
          draft.counterAccountId == null ||
          draft.counterAmountMinor == null ||
          draft.counterCurrencyCode == null ||
          draft.amountMinor >= BigInt.zero ||
          draft.counterAmountMinor! <= BigInt.zero ||
          draft.accountId == draft.counterAccountId) {
        return const AuthFailure(AuthError.invalidInput);
      }
      if (draft.currencyCode == draft.counterCurrencyCode &&
          draft.amountMinor + draft.counterAmountMinor! != BigInt.zero) {
        return const AuthFailure(AuthError.invalidInput);
      }
    } else {
      return const AuthFailure(AuthError.invalidInput);
    }
    return null;
  }

  @override
  Future<Either<AuthFailure, List<RecurringRule>>> list({bool? active}) =>
      _repository.list(active: active);

  @override
  Future<Either<AuthFailure, RecurringRule>> create(RecurringDraft draft) {
    final error = _validateDraft(draft);
    if (error != null) return Future.value(left(error));
    return _repository.create(draft);
  }

  @override
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
    String? name,
    String? amountKind,
    int? remindDaysBefore,
  }) {
    final next = rule.copyWith(
      unit: unit,
      interval: interval,
      amountMinor: amountMinor,
      currencyCode: currencyCode,
      accountId: accountId,
      categoryId: categoryId,
      clearCategory: clearCategory,
      counterAccountId: counterAccountId,
      clearCounter: clearCounter,
      counterAmountMinor: counterAmountMinor,
      counterCurrencyCode: counterCurrencyCode,
      fxRate: fxRate,
      clearFx: clearFx,
      startDate: startDate,
      endDate: endDate,
      clearEnd: clearEnd,
      nextExecutionDate: nextExecutionDate,
      active: active,
      name: name,
      amountKind: amountKind,
      remindDaysBefore: remindDaysBefore,
    );
    final error = _validateDraft(
      RecurringDraft(
        clientId: next.clientId,
        type: next.type,
        unit: next.unit,
        interval: next.interval,
        amountMinor: next.amountMinor,
        currencyCode: next.currencyCode,
        accountId: next.accountId,
        categoryId: next.categoryId,
        counterAccountId: next.counterAccountId,
        counterAmountMinor: next.counterAmountMinor,
        counterCurrencyCode: next.counterCurrencyCode,
        fxRate: next.fxRate,
        startDate: next.startDate,
        endDate: next.endDate,
        nextExecutionDate: next.nextExecutionDate,
        active: next.active,
        mode: next.mode,
        name: next.name,
        amountKind: next.amountKind,
        remindDaysBefore: next.remindDaysBefore,
      ),
    );
    if (error != null) return Future.value(left(error));
    return _repository.update(
      rule,
      unit: unit,
      interval: interval,
      amountMinor: amountMinor,
      currencyCode: currencyCode,
      accountId: accountId,
      categoryId: categoryId,
      clearCategory: clearCategory,
      counterAccountId: counterAccountId,
      clearCounter: clearCounter,
      counterAmountMinor: counterAmountMinor,
      counterCurrencyCode: counterCurrencyCode,
      fxRate: fxRate,
      clearFx: clearFx,
      startDate: startDate,
      endDate: endDate,
      clearEnd: clearEnd,
      nextExecutionDate: nextExecutionDate,
      active: active,
      name: name,
      amountKind: amountKind,
      remindDaysBefore: remindDaysBefore,
    );
  }

  @override
  Future<Either<AuthFailure, Unit>> delete(RecurringRule rule) =>
      _repository.delete(rule);

  @override
  Future<Either<AuthFailure, RecurringConfirmResult>> confirm(
    RecurringRule rule,
    RecurringConfirm confirm,
  ) {
    final amount = confirm.amountMinor;
    final linked = confirm.transactionId != null;
    if (!rule.isRemind ||
        parseCalendarParts(confirm.occurredOn) == null ||
        (amount != null && amount <= BigInt.zero) ||
        (linked && (amount != null || confirm.accountId != null)) ||
        (confirm.paidOn != null &&
            parseCalendarParts(confirm.paidOn!) == null)) {
      return Future.value(left(const AuthFailure(AuthError.invalidInput)));
    }
    return _repository.confirm(rule, confirm);
  }

  @override
  Future<Either<AuthFailure, RecurringRunResult>> run() => _repository.run();
}
