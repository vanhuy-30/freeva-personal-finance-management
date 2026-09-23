import 'package:flutter/material.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../viewmodels/auth_view_model.dart';
import 'auth_fields.dart';
import 'auth_header.dart';
import 'auth_message.dart';
import 'auth_primary_button.dart';

class AuthFlowContent extends StatelessWidget {
  const AuthFlowContent(
      {required this.model,
      required this.email,
      required this.password,
      required this.confirmation,
      required this.token,
      required this.onSubmit,
      required this.onForgotPassword,
      super.key});
  final AuthViewModel model;
  final TextEditingController email, password, confirmation, token;
  final VoidCallback onSubmit, onForgotPassword;
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AuthHeader(step: model.step, email: model.email),
      const SizedBox(height: 32),
      AuthFields(
          step: model.step,
          email: email,
          password: password,
          confirmation: confirmation,
          token: token,
          enabled: !model.loading,
          onSubmit: onSubmit),
      if (model.step == AuthStep.password)
        Align(
            alignment: Alignment.centerRight,
            child: TextButton(
                onPressed: model.loading ? null : onForgotPassword,
                child: Text(s.authForgotPassword))),
      AuthMessage(model: model),
      const SizedBox(height: 20),
      AuthPrimaryButton(
          loading: model.loading,
          onPressed: onSubmit,
          label: switch (model.step) {
            AuthStep.email => s.authContinue,
            AuthStep.password => s.authLogin,
            AuthStep.register => s.authCreateAccount,
            AuthStep.verification => s.authVerifyAndContinue,
            AuthStep.forgotPassword => s.authSendResetCode,
            AuthStep.resetPassword => s.authSavePassword,
          }),
      if (model.step == AuthStep.verification)
        Padding(
            padding: const EdgeInsets.only(top: 16),
            child: TextButton(
                onPressed: model.loading ? null : model.resendVerification,
                child: Text(s.authResendCode))),
      const SizedBox(height: 28),
      Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lock_outline_rounded,
                size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Flexible(
                child: Text(s.authSecurityNote,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(height: 1.6))),
          ]),
    ]);
  }
}
