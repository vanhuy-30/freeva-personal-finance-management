import 'package:flutter/material.dart';
import '../viewmodels/auth_view_model.dart';
import '../widgets/auth_flow_content.dart';
import '../widgets/auth_shell.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({required this.model, super.key});
  final AuthViewModel model;
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  late final _email = TextEditingController(text: widget.model.email);
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  final _token = TextEditingController();

  void _clearSecrets() {
    _password.clear();
    _confirmation.clear();
    _token.clear();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    _token.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final model = widget.model;
    if (model.step == AuthStep.email) {
      await model.continueEmail(_email.text);
    } else {
      await model.submitStep(
          password: _password.text,
          confirmation: _confirmation.text,
          token: _token.text);
      if (mounted) _clearSecrets();
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    return AuthShell(
      key: ValueKey(model.step),
      canGoBack: model.step != AuthStep.email,
      onBack: model.loading
          ? null
          : () {
              _clearSecrets();
              model.back();
            },
      child: AuthFlowContent(
          model: model,
          email: _email,
          password: _password,
          confirmation: _confirmation,
          token: _token,
          onSubmit: _submit,
          onForgotPassword: () {
            _clearSecrets();
            model.forgotPassword();
          }),
    );
  }
}
