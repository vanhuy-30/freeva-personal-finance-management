import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../auth/domain/auth_repository.dart';
import '../viewmodels/profile_view_model.dart';

class ProfileStatus extends StatelessWidget {
  const ProfileStatus({required this.model, super.key});
  final ProfileViewModel model;
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final failure = model.failure;
    final message = failure == null
        ? (model.succeeded ? s.profileSaved : null)
        : switch (failure.code) {
            AuthError.conflict => s.profileConflict,
            AuthError.invalidInput ||
            AuthError.invalidToken => s.profileInvalid,
            AuthError.network => s.authNetworkError,
            AuthError.rateLimited => s.authRateLimited(
              failure.retryAfter ?? 900,
            ),
            _ => model.saved == null ? s.profileLoadError : s.profileSaveError,
          };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (message != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Semantics(
              liveRegion: true,
              child: Text(
                message,
                style: TextStyle(
                  color: failure == null
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ),
        if (failure != null &&
            (model.saved == null || failure.code == AuthError.conflict))
          OutlinedButton(
            onPressed: model.loading ? null : model.load,
            child: Text(s.profileReload),
          ),
      ],
    );
  }
}
