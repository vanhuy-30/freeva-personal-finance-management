import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../domain/transaction.dart';

String transactionTypeLabel(S s, TransactionType type) => switch (type) {
  TransactionType.expense => s.transactionExpense,
  TransactionType.income => s.transactionIncome,
  TransactionType.transfer => s.transactionTransfer,
};

String transactionError(S s, AuthFailure error) => switch (error.code) {
  AuthError.conflict => s.transactionConflict,
  AuthError.invalidInput || AuthError.invalidToken => s.transactionInvalid,
  AuthError.network => s.authNetworkError,
  AuthError.rateLimited => s.authRateLimited(error.retryAfter ?? 900),
  _ => s.transactionError,
};
