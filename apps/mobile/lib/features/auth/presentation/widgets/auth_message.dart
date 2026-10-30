import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_banner.dart';
import '../../domain/auth_repository.dart';
import '../viewmodels/auth_view_model.dart';

/// Result of the last action on an account screen: a danger banner for a
/// failure, a success banner for a notice. Nothing when there is neither.
class AuthMessage extends StatelessWidget {
  const AuthMessage({required this.model, super.key});

  final AuthViewModel model;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final failure = model.failure;
    final notice = model.notice;
    if (failure == null && notice != AuthNotice.passwordChanged) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: FreevaSpace.s3),
      child: failure == null
          ? FreevaBanner(
              message: s.authPasswordChanged,
              icon: LucideIcons.circleCheck,
              tone: FreevaBannerTone.success,
            )
          : FreevaBanner(
              message: authFailureText(s, failure),
              icon: LucideIcons.circleAlert,
              tone: FreevaBannerTone.danger,
            ),
    );
  }
}

String authFailureText(S s, AuthFailure failure) => switch (failure.code) {
  AuthError.conflict => s.profileConflict,
  AuthError.invalidInput => s.authInvalidInput,
  AuthError.categoryKind => s.transactionCategoryKind,
  AuthError.invalidEmail => s.authInvalidEmail,
  AuthError.passwordMismatch => s.authPasswordMismatch,
  AuthError.credentials => s.authInvalidCredentials,
  AuthError.invalidToken => s.authInvalidToken,
  AuthError.rateLimited => s.authRateLimited(failure.retryAfter ?? 900),
  AuthError.network => s.authNetworkError,
  AuthError.storage => s.authStorageError,
  AuthError.unavailable => s.authUnavailable,
  AuthError.wrongPin => s.authWrongPin,
  AuthError.expired => s.authExpired,
};
