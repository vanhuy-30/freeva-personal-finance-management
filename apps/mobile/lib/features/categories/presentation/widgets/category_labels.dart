import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../auth/domain/auth_repository.dart';

String categoryError(S s, AuthFailure error) => switch (error.code) {
  AuthError.conflict => s.categoryConflict,
  AuthError.invalidInput || AuthError.invalidToken => s.categoryInvalid,
  AuthError.network => s.authNetworkError,
  AuthError.rateLimited => s.authRateLimited(error.retryAfter ?? 900),
  _ => s.categoryError,
};
