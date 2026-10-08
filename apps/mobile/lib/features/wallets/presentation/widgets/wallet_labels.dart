import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../domain/wallet.dart';

String walletTypeLabel(S s, WalletType type) => switch (type) {
  WalletType.cash => s.walletCash,
  WalletType.bank => s.walletBank,
  WalletType.ewallet => s.walletEwallet,
  WalletType.credit => s.walletCredit,
};
String walletError(S s, AuthFailure error) => switch (error.code) {
  AuthError.conflict => s.walletConflict,
  AuthError.invalidInput || AuthError.invalidToken => s.walletInvalid,
  AuthError.network => s.authNetworkError,
  AuthError.rateLimited => s.authRateLimited(error.retryAfter ?? 900),
  _ => s.walletError,
};
