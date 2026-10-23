import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/consent_checkbox.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_pill_field.dart';
import '../../../../core/widgets/password_checklist.dart';
import '../../domain/password_check.dart';
import '../viewmodels/auth_view_model.dart';
import '../widgets/auth_message.dart';
import '../widgets/auth_scaffold.dart';

/// Tạo tài khoản bằng email: password with a live checklist, repeat, and
/// the Terms checkbox.
class RegisterPage extends StatefulWidget {
  const RegisterPage({required this.model, super.key});

  final AuthViewModel model;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  late final _email = TextEditingController(text: widget.model.email);
  final _password = TextEditingController();
  final _repeat = TextEditingController();
  var _agreed = false;

  PasswordCheck get _check => PasswordCheck(_password.text, _repeat.text);

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _repeat.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    await widget.model.register(
      _email.text,
      _password.text,
      _repeat.text,
      termsAccepted: _agreed,
    );
    if (!mounted) return;
    _password.clear();
    _repeat.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final model = widget.model;
    final idle = !model.loading;
    final ready = _check.valid && _check.matches && _agreed;
    return AuthScaffold(
      title: s.authCreateAccount,
      onBack: idle ? () => model.goTo(AuthStep.signUp) : null,
      footer: AuthSwitchLink(
        prompt: s.authHaveAccount,
        action: s.authLogin,
        onTap: idle ? () => model.goTo(AuthStep.login) : null,
      ),
      children: [
        const SizedBox(height: FreevaSpace.s6),
        AutofillGroup(
          child: Column(
            children: [
              FreevaPillField(
                label: s.authEmail,
                icon: LucideIcons.mail,
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 10),
              FreevaPillField(
                label: s.authPassword,
                icon: LucideIcons.lock,
                controller: _password,
                obscure: true,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              FreevaPillField(
                label: s.authConfirmPassword,
                icon: LucideIcons.lock,
                controller: _repeat,
                obscure: true,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),
        const SizedBox(height: FreevaSpace.s3),
        PasswordStrengthBar(check: _check),
        const SizedBox(height: FreevaSpace.s3),
        PasswordChecklist(check: _check),
        const SizedBox(height: FreevaSpace.s3),
        ConsentCheckbox(
          checked: _agreed,
          onChanged: (value) => setState(() => _agreed = value),
          onTerms: () => context.push('/help/legal?doc=terms'),
          onPrivacy: () => context.push('/help/legal?doc=privacy'),
        ),
        AuthMessage(model: model),
        const SizedBox(height: FreevaSpace.s4),
        FreevaButton(
          label: s.authCreateAccount,
          size: FreevaButtonSize.l,
          expand: true,
          loading: model.loading,
          onPressed: ready ? _submit : null,
        ),
      ],
    );
  }
}
