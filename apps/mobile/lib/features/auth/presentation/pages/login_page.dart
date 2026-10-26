import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_pill_field.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../../../core/widgets/social_sign_in_button.dart';
import '../viewmodels/auth_view_model.dart';
import '../widgets/auth_message.dart';
import '../widgets/auth_scaffold.dart';

/// Đăng nhập: email and password on one screen.
class LoginPage extends StatefulWidget {
  const LoginPage({required this.model, super.key});

  final AuthViewModel model;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final _email = TextEditingController(text: widget.model.email);
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    await widget.model.login(_email.text, _password.text);
    if (mounted) _password.clear();
  }

  void _soon() =>
      showFreevaToast(context, message: S.of(context).authSocialSoon);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final model = widget.model;
    final idle = !model.loading;
    return AuthScaffold(
      title: s.authLogin,
      topGap: 56,
      footer: AuthSwitchLink(
        prompt: s.authNoAccount,
        action: s.authRegister,
        onTap: idle ? () => model.goTo(AuthStep.signUp) : null,
      ),
      children: [
        const SizedBox(height: FreevaSpace.s8),
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
              const SizedBox(height: FreevaSpace.s3),
              FreevaPillField(
                label: s.authPassword,
                icon: LucideIcons.lock,
                controller: _password,
                obscure: true,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.go,
                onSubmitted: idle ? (_) => _submit() : null,
              ),
            ],
          ),
        ),
        Center(
          child: TextButton(
            onPressed: idle ? () => model.goTo(AuthStep.forgot) : null,
            child: Text(
              s.authRecoverTitle,
              style: FreevaTypography.label.copyWith(
                color: c.textPrimary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
        AuthMessage(model: model),
        const SizedBox(height: FreevaSpace.s2),
        FreevaButton(
          label: s.authLogin,
          size: FreevaButtonSize.l,
          expand: true,
          loading: model.loading,
          onPressed: _submit,
        ),
        const _OrDivider(),
        SocialSignInButton(
          provider: SocialProvider.google,
          label: s.authContinueGoogle,
          onPressed: _soon,
        ),
        const SizedBox(height: 10),
        SocialSignInButton(
          provider: SocialProvider.apple,
          label: s.authContinueApple,
          onPressed: _soon,
        ),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FreevaSpace.s6),
      child: Row(
        children: [
          Expanded(child: Divider(height: 1, color: c.borderDivider)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: FreevaSpace.s3),
            child: Text(
              S.of(context).authOr,
              style: FreevaTypography.bodyS.copyWith(color: c.textSecondary),
            ),
          ),
          Expanded(child: Divider(height: 1, color: c.borderDivider)),
        ],
      ),
    );
  }
}
