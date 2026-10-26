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

/// "VND · Đồng Việt Nam" for the currency field; the code alone when the app
/// has no name for it.
String currencyLabel(S s, String code) {
  final name = switch (code) {
    'VND' => s.currencyNameVnd,
    'USD' => s.currencyNameUsd,
    'EUR' => s.currencyNameEur,
    'JPY' => s.currencyNameJpy,
    'KRW' => s.currencyNameKrw,
    'CNY' => s.currencyNameCny,
    'SGD' => s.currencyNameSgd,
    'THB' => s.currencyNameThb,
    'AUD' => s.currencyNameAud,
    'GBP' => s.currencyNameGbp,
    _ => null,
  };
  return name == null ? code : s.currencyCodeName(code, name);
}
