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
import '../widgets/key_glyph.dart';

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
      narrow: true,
      topGap: 28,
      footer: sent
          ? FreevaButton(
              label: s.authBackToLogin,
              size: FreevaButtonSize.l,
              expand: true,
              onPressed: () => model.goTo(AuthStep.login),
            )
          : FreevaButton(
              label: s.authSendResetLink,
              size: FreevaButtonSize.l,
              expand: true,
              loading: model.loading,
              onPressed: _submit,
            ),
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: c.tintViolet,
              borderRadius: BorderRadius.circular(FreevaRadius.lgx),
            ),
            alignment: Alignment.center,
            child: sent
                ? Icon(LucideIcons.mailCheck, size: 30, color: c.tintVioletFg)
                : KeyGlyph(color: c.tintVioletFg, size: 30, strokeWidth: 1.6),
          ),
        ),
        const SizedBox(height: FreevaSpace.s5),
        AuthTitle(
          sent ? s.authResetSentTitle : s.authRecoverTitle,
          subtitle: sent ? s.authResetSent(model.email) : s.authRecoverSubtitle,
          start: true,
          subtitleGap: 10,
        ),
        const SizedBox(height: FreevaSpace.s6),
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
        ],
      ],
    );
  }
}
