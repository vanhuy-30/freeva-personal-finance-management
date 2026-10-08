import 'package:flutter/material.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../domain/auth_repository.dart';
import '../viewmodels/auth_view_model.dart';

class AuthMessage extends StatelessWidget {
  const AuthMessage({required this.model, super.key});
  final AuthViewModel model;
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final failure = model.failure;
    if (failure == null && !model.succeeded) return const SizedBox.shrink();
    final message = failure == null
        ? switch (model.notice) {
            AuthNotice.emailSent => s.authCodeResent,
            AuthNotice.verified => s.authVerifiedNotice,
            AuthNotice.passwordChanged => s.authPasswordChanged,
            null => s.authSuccess,
          }
        : switch (failure.code) {
            AuthError.conflict => s.profileConflict,
            AuthError.invalidInput => s.authInvalidInput,
            AuthError.invalidEmail => s.authInvalidEmail,
            AuthError.passwordMismatch => s.authPasswordMismatch,
            AuthError.credentials => s.authInvalidCredentials,
            AuthError.invalidToken => s.authInvalidToken,
            AuthError.rateLimited =>
              s.authRateLimited(failure.retryAfter ?? 900),
            AuthError.network => s.authNetworkError,
            AuthError.storage => s.authStorageError,
            AuthError.unavailable => s.authUnavailable,
            AuthError.wrongPin => s.authWrongPin,
            AuthError.expired => s.authExpired,
          };
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Semantics(
            liveRegion: true,
            child: Text(message,
                style: TextStyle(
                    color: failure == null
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error))));
  }
}
