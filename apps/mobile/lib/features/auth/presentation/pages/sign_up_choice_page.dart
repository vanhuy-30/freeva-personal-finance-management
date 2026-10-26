import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../../../core/widgets/social_sign_in_button.dart';
import '../viewmodels/auth_view_model.dart';
import '../widgets/auth_scaffold.dart';

/// Tạo tài khoản Freeva: Google, Apple or email. The social buttons say
/// "Sắp có" until OAuth lands on mobile.
class SignUpChoicePage extends StatelessWidget {
  const SignUpChoicePage({required this.model, super.key});

  final AuthViewModel model;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    void soon() => showFreevaToast(context, message: s.authSocialSoon);
    return AuthScaffold(
      onBack: () => model.goTo(AuthStep.welcome),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthSwitchLink(
            prompt: s.authHaveAccount,
            action: s.authLogin,
            onTap: () => model.goTo(AuthStep.login),
          ),
          const SizedBox(height: FreevaSpace.s2),
          const _TermsNote(),
        ],
      ),
      children: [
        const SizedBox(height: FreevaSpace.s4),
        Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: c.tintBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.sprout, size: 48, color: c.tintBlueFg),
          ),
        ),
        const SizedBox(height: FreevaSpace.s6),
        AuthTitle(s.signUpTitle, subtitle: s.signUpSub),
        const SizedBox(height: FreevaSpace.s8),
        SocialSignInButton(
          provider: SocialProvider.google,
          label: s.authContinueGoogle,
          onPressed: soon,
        ),
        const SizedBox(height: 10),
        SocialSignInButton(
          provider: SocialProvider.apple,
          label: s.authContinueApple,
          onPressed: soon,
        ),
        const SizedBox(height: 10),
        SocialSignInButton(
          provider: SocialProvider.email,
          label: s.authContinueEmail,
          onPressed: () => model.goTo(AuthStep.register),
        ),
      ],
    );
  }
}

/// "Tiếp tục nghĩa là bạn đồng ý với Điều khoản và Chính sách."
class _TermsNote extends StatefulWidget {
  const _TermsNote();

  @override
  State<_TermsNote> createState() => _TermsNoteState();
}

class _TermsNoteState extends State<_TermsNote> {
  late final _terms = TapGestureRecognizer()
    ..onTap = () => context.push('/help/legal?doc=terms');
  late final _privacy = TapGestureRecognizer()
    ..onTap = () => context.push('/help/legal?doc=privacy');

  @override
  void dispose() {
    _terms.dispose();
    _privacy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final small = FreevaTypography.bodyS.copyWith(
      fontSize: 13,
      color: c.textSecondary,
    );
    final link = small.copyWith(
      color: c.textPrimary,
      decoration: TextDecoration.underline,
    );
    return Text.rich(
      TextSpan(
        style: small,
        children: [
          TextSpan(text: s.signUpTermsPrefix),
          TextSpan(text: s.consentTerms, style: link, recognizer: _terms),
          TextSpan(text: s.consentAnd),
          TextSpan(text: s.consentPrivacy, style: link, recognizer: _privacy),
          TextSpan(text: s.signUpTermsSuffix),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
