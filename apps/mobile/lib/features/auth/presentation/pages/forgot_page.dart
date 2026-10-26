import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_pill_field.dart';
import '../viewmodels/auth_view_model.dart';
import '../widgets/auth_message.dart';
import '../widgets/auth_scaffold.dart';

/// Quên mật khẩu: one email field; after sending, the same screen says to
/// check the mail (the reply never says whether the account exists).
class ForgotPage extends StatefulWidget {
  const ForgotPage({required this.model, super.key});

  final AuthViewModel model;

  @override
  State<ForgotPage> createState() => _ForgotPageState();
}

class _ForgotPageState extends State<ForgotPage> {
  late final _email = TextEditingController(text: widget.model.email);

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() {
    FocusScope.of(context).unfocus();
    return widget.model.requestReset(_email.text);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final model = widget.model;
    final sent = model.notice == AuthNotice.resetSent;
    return AuthScaffold(
      onBack: model.loading ? null : () => model.goTo(AuthStep.login),
      children: [
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: c.tintBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(
              sent ? LucideIcons.mailCheck : LucideIcons.keyRound,
              size: 32,
              color: c.tintBlueFg,
            ),
          ),
        ),
        const SizedBox(height: FreevaSpace.s5),
        AuthTitle(
          sent ? s.authResetSentTitle : s.authRecoverTitle,
          subtitle: sent ? s.authResetSent(model.email) : s.authRecoverSubtitle,
        ),
        const SizedBox(height: FreevaSpace.s8),
        if (!sent) ...[
          FreevaPillField(
            label: s.authEmail,
            icon: LucideIcons.mail,
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.go,
            onSubmitted: model.loading ? null : (_) => _submit(),
          ),
          AuthMessage(model: model),
          const SizedBox(height: FreevaSpace.s5),
          FreevaButton(
            label: s.authSendResetLink,
            size: FreevaButtonSize.l,
            expand: true,
            loading: model.loading,
            onPressed: _submit,
          ),
        ] else
          FreevaButton(
            label: s.authBackToLogin,
            size: FreevaButtonSize.l,
            expand: true,
            onPressed: () => model.goTo(AuthStep.login),
          ),
      ],
    );
  }
}
