import 'package:flutter/material.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../viewmodels/auth_view_model.dart';
import 'auth_password_field.dart';

class AuthFields extends StatelessWidget {
  const AuthFields(
      {required this.step,
      required this.email,
      required this.password,
      required this.confirmation,
      required this.token,
      required this.enabled,
      required this.onSubmit,
      super.key});
  final AuthStep step;
  final TextEditingController email, password, confirmation, token;
  final bool enabled;
  final VoidCallback onSubmit;
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final newPassword =
        step == AuthStep.register || step == AuthStep.resetPassword;
    return AutofillGroup(
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (step == AuthStep.email)
        TextField(
            key: const ValueKey('auth-email'),
            controller: email,
            enabled: enabled,
            decoration: InputDecoration(
                hintText: s.authEmailPlaceholder, labelText: s.authEmail),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.go,
            onSubmitted: enabled ? (_) => onSubmit() : null,
            autocorrect: false,
            autofillHints: const [AutofillHints.email]),
      if (step == AuthStep.verification || step == AuthStep.resetPassword) ...[
        TextField(
            key: const ValueKey('auth-code'),
            controller: token,
            enabled: enabled,
            decoration: InputDecoration(labelText: s.authEmailCode),
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const [AutofillHints.oneTimeCode],
            textInputAction: step == AuthStep.verification
                ? TextInputAction.go
                : TextInputAction.next,
            onSubmitted: enabled && step == AuthStep.verification
                ? (_) => onSubmit()
                : null),
        if (newPassword) const SizedBox(height: 18),
      ],
      if (step == AuthStep.password || newPassword)
        AuthPasswordField(
            key: ValueKey(step),
            controller: password,
            enabled: enabled,
            label: newPassword ? s.authNewPassword : s.authPassword,
            helper: newPassword ? s.authPasswordHelp : null,
            newPassword: newPassword,
            onSubmit: newPassword ? null : onSubmit),
      if (newPassword) ...[
        const SizedBox(height: 18),
        AuthPasswordField(
            controller: confirmation,
            enabled: enabled,
            label: s.authConfirmPassword,
            newPassword: true,
            onSubmit: onSubmit),
      ],
    ]));
  }
}
