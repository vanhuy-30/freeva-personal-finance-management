import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/check_mark.dart';
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
    final c = context.colors;
    final model = widget.model;
    return AuthScaffold(
      onBack: model.loading ? null : () => model.goTo(AuthStep.login),
      backIcon: LucideIcons.x,
      backLabel: s.commonClose,
      narrow: true,
      topGap: 28,
      footer: FreevaButton(
        label: s.authSaveAndLogin,
        size: FreevaButtonSize.l,
        expand: true,
        loading: model.loading,
        onPressed: _check.valid && _check.matches ? _submit : null,
      ),
      children: [
        // The link names the account; shown once the email is known.
        if (model.email.isNotEmpty) ...[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Container(
              height: FreevaSize.pill,
              padding: const EdgeInsetsDirectional.fromSTEB(8, 0, 12, 0),
              decoration: BoxDecoration(
                color: c.statusSuccessBg,
                borderRadius: BorderRadius.circular(FreevaRadius.full),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckMark(color: c.statusSuccess, size: 16, strokeWidth: 2.4),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      s.authResetVerified(model.email),
                      overflow: TextOverflow.ellipsis,
                      style: FreevaTypography.bodyS.copyWith(
                        fontWeight: FontWeight.w600,
                        color: c.statusSuccess,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: FreevaSpace.s4),
        ],
        AuthTitle(s.authNewPasswordTitle, start: true),
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
                icon: LucideIcons.shieldCheck,
                controller: _repeat,
                obscure: true,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        PasswordStrengthBar(check: _check, segmentHeight: 6),
        const SizedBox(height: FreevaSpace.s3),
        PasswordChecklist(check: _check),
        AuthMessage(model: model),
      ],
    );
  }
}
