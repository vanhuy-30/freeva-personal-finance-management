import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../auth/domain/auth_repository.dart';

String reportFailure(S s, AuthFailure error) => switch (error.code) {
  AuthError.invalidInput => s.reportInvalid,
  AuthError.network => s.authNetworkError,
  AuthError.rateLimited => s.authRateLimited(error.retryAfter ?? 900),
  _ => s.reportError,
};
