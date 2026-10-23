import 'package:flutter/material.dart';

import '../viewmodels/auth_view_model.dart';
import 'forgot_page.dart';
import 'login_page.dart';
import 'sign_up_choice_page.dart';
import 'welcome_page.dart';
import 'register_page.dart';
import 'reset_password_page.dart';

/// Signed-out flow: sign in, sign up, forgot password, new password.
class AuthPage extends StatelessWidget {
  const AuthPage({required this.model, super.key});

  final AuthViewModel model;

  @override
  Widget build(BuildContext context) {
    // Android back goes to sign-in from the other screens instead of leaving.
    return PopScope(
      canPop: model.step == AuthStep.login || model.step == AuthStep.welcome,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) model.goTo(AuthStep.login);
      },
      child: switch (model.step) {
        AuthStep.welcome => WelcomePage(
          key: const ValueKey('welcome'),
          model: model,
        ),
        AuthStep.signUp => SignUpChoicePage(
          key: const ValueKey('signUp'),
          model: model,
        ),
        AuthStep.login => LoginPage(key: const ValueKey('login'), model: model),
        AuthStep.register => RegisterPage(
          key: const ValueKey('register'),
          model: model,
        ),
        AuthStep.forgot => ForgotPage(
          key: const ValueKey('forgot'),
          model: model,
        ),
        AuthStep.reset => ResetPasswordPage(
          key: const ValueKey('reset'),
          model: model,
        ),
      },
    );
  }
}
