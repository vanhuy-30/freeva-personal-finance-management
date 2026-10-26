import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../../../core/widgets/social_sign_in_button.dart';
import '../viewmodels/auth_view_model.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/coin_rest_illustration.dart';

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
      topGap: FreevaSpace.s2,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          const SizedBox(height: FreevaSpace.s2),
          AuthSwitchLink(
            prompt: s.authHaveAccount,
            action: s.authLogin,
            onTap: () => model.goTo(AuthStep.login),
          ),
          const SizedBox(height: FreevaSpace.s1),
          const _TermsNote(),
        ],
      ),
      children: [
        const Center(child: CoinRestIllustration()),
        const SizedBox(height: FreevaSpace.s3),
        Semantics(
          header: true,
          child: Text(
            s.signUpTitle,
            textAlign: TextAlign.center,
            style: FreevaTypography.titleXl.copyWith(
              height: 34 / 28,
              color: c.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: FreevaSpace.s2),
        Text(
          s.signUpSub,
          textAlign: TextAlign.center,
          style: FreevaTypography.body.copyWith(color: c.textSecondary),
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
      fontSize: 12,
      height: 1.5,
      color: c.textSecondary,
    );
    final link = small.copyWith(
      color: c.textOnWash,
      decoration: TextDecoration.underline,
    );
    return Text.rich(
      TextSpan(
        style: small,
        children: [
          TextSpan(text: s.signUpTermsPrefix),
          TextSpan(text: s.signUpTermsLink, style: link, recognizer: _terms),
          TextSpan(text: s.consentAnd),
          TextSpan(text: s.consentPrivacy, style: link, recognizer: _privacy),
          TextSpan(text: s.signUpTermsSuffix),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
