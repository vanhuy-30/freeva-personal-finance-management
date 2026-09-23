import 'package:flutter/material.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/brand_symbol.dart';
import '../viewmodels/auth_view_model.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({required this.step, required this.email, super.key});
  final AuthStep step;
  final String email;
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    final title = switch (step) {
      AuthStep.email => s.authWelcomeTitle,
      AuthStep.password => s.authWelcomeBack,
      AuthStep.register => s.authCreateTitle,
      AuthStep.verification => s.authVerifyTitle,
      AuthStep.forgotPassword => s.authRecoverTitle,
      AuthStep.resetPassword => s.authNewPasswordTitle,
    };
    final subtitle = switch (step) {
      AuthStep.email => s.authWelcomeSubtitle,
      AuthStep.password => s.authLoginSubtitle,
      AuthStep.register => s.authRegisterSubtitle,
      AuthStep.verification => s.authVerifySubtitle,
      AuthStep.forgotPassword => s.authRecoverSubtitle,
      AuthStep.resetPassword => s.authResetSubtitle,
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const BrandSymbol(size: 60),
      const SizedBox(height: 28),
      Semantics(
          header: true,
          child: Text(title,
              style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                  letterSpacing: -0.5))),
      const SizedBox(height: 12),
      Text(subtitle,
          style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.6,
              color: theme.brightness == Brightness.dark
                  ? AppColors.darkText
                  : AppColors.textMuted)),
      if (step != AuthStep.email) ...[
        const SizedBox(height: 16),
        Row(children: [
          Icon(Icons.alternate_email_rounded,
              size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
              child: Text(email,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600))),
        ]),
      ],
    ]);
  }
}
