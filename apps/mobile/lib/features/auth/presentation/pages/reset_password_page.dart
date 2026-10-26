import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_pill_field.dart';
import '../../../../core/widgets/password_checklist.dart';
import '../../domain/password_check.dart';
import '../viewmodels/auth_view_model.dart';
import '../widgets/auth_message.dart';
import '../widgets/auth_scaffold.dart';

/// Đặt mật khẩu mới: opened from the link in the reset email
/// ([AuthViewModel.startReset]). Same rules and checklist as sign-up.
class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({required this.model, super.key});

  final AuthViewModel model;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _password = TextEditingController();
  final _repeat = TextEditingController();

  PasswordCheck get _check => PasswordCheck(_password.text, _repeat.text);

  @override
  void dispose() {
    _password.dispose();
    _repeat.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    await widget.model.resetPassword('', _password.text, _repeat.text);
    if (!mounted) return;
    _password.clear();
    _repeat.clear();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final model = widget.model;
    return AuthScaffold(
      title: s.authNewPasswordTitle,
      onBack: model.loading ? null : () => model.goTo(AuthStep.login),
      children: [
        const SizedBox(height: FreevaSpace.s6),
        AutofillGroup(
          child: Column(
            children: [
              FreevaPillField(
                label: s.authNewPassword,
                icon: LucideIcons.lock,
                controller: _password,
                obscure: true,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              FreevaPillField(
                label: s.authConfirmNewPassword,
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
        AuthMessage(model: model),
        const SizedBox(height: FreevaSpace.s6),
        FreevaButton(
          label: s.authSaveAndLogin,
          size: FreevaButtonSize.l,
          expand: true,
          loading: model.loading,
          onPressed: _check.valid && _check.matches ? _submit : null,
        ),
      ],
    );
  }
}
