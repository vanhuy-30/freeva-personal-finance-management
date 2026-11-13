import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/widgets/freeva_dialog_input.dart';
import '../../../auth/domain/auth_repository.dart';

/// Asks for the password before a whole-account export or delete
/// (SEC-P6-002). Null when the user cancels or leaves it empty.
Future<String?> askAccountPassword(BuildContext context) async {
  final s = S.of(context);
  final password = await showFreevaInputDialog(
    context: context,
    title: s.meConfirmPasswordTitle,
    label: s.authPassword,
    keyboardType: TextInputType.visiblePassword,
    obscure: true,
  );
  return password == null || password.isEmpty ? null : password;
}

/// Toast text after a refused export or delete; [fallback] for other errors.
String accountStepUpError(S s, AuthFailure failure, String fallback) =>
    switch (failure.code) {
      AuthError.credentials => s.mePasswordWrong,
      AuthError.rateLimited => s.meBusyRetry(
        ((failure.retryAfter ?? 900) / 60).ceil(),
      ),
      _ => fallback,
    };
