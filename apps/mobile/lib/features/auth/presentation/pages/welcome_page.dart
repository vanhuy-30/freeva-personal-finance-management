import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../viewmodels/auth_view_model.dart';
import '../widgets/auth_scaffold.dart';

/// First launch: what Freeva is in one line, then Bắt đầu or Đăng nhập.
class WelcomePage extends StatelessWidget {
  const WelcomePage({required this.model, super.key});

  final AuthViewModel model;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    return AuthScaffold(
      topGap: FreevaSpace.s2,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FreevaButton(
            label: s.welcomeStart,
            size: FreevaButtonSize.l,
            expand: true,
            onPressed: () => model.leaveWelcome(AuthStep.signUp),
          ),
          const SizedBox(height: FreevaSpace.s2),
          AuthSwitchLink(
            prompt: s.authHaveAccount,
            action: s.authLogin,
            onTap: () => model.leaveWelcome(AuthStep.login),
          ),
        ],
      ),
      children: [
        const _SampleCards(),
        const SizedBox(height: FreevaSpace.s8),
        Semantics(
          header: true,
          child: Text(
            '${s.welcomeTitleLine1}\n${s.welcomeTitleLine2}',
            textAlign: TextAlign.center,
            style: FreevaTypography.titleXl.copyWith(color: c.textPrimary),
          ),
        ),
        const SizedBox(height: FreevaSpace.s3),
        Text(
          s.welcomeSub,
          textAlign: TextAlign.center,
          style: FreevaTypography.body.copyWith(color: c.textSecondary),
        ),
      ],
    );
  }
}

/// Decorative piece of the app: a balance card, two rows and the + button.
/// Hidden from screen readers; the numbers are only an example.
class _SampleCards extends StatelessWidget {
  const _SampleCards();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    return ExcludeSemantics(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(FreevaSpace.s5),
            decoration: BoxDecoration(
              color: c.bgWash,
              borderRadius: BorderRadius.circular(FreevaRadius.xl),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.welcomeSampleBalance,
                  style: FreevaTypography.bodyS.copyWith(color: c.textOnWash),
                ),
                const SizedBox(height: FreevaSpace.s1),
                // Decorative sample: scaling it down is fine here.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '24.600.000 ₫',
                    style: FreevaTypography.moneyDisplay.copyWith(
                      color: c.textOnWash,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: FreevaSpace.s3),
          FreevaCard(
            list: true,
            child: Column(
              children: [
                _Row(LucideIcons.utensils, s.welcomeSampleFood, '−65.000'),
                const SizedBox(height: FreevaSpace.s3),
                _Row(
                  LucideIcons.banknote,
                  s.welcomeSampleSalary,
                  '+18.500.000',
                  income: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: FreevaSpace.s4),
          Container(
            width: FreevaSize.fab,
            height: FreevaSize.fab,
            decoration: BoxDecoration(
              color: c.actionPrimary,
              shape: BoxShape.circle,
              boxShadow: FreevaElevation.fab,
            ),
            child: Icon(LucideIcons.plus, color: c.textOnAction),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.icon, this.title, this.amount, {this.income = false});

  final IconData icon;
  final String title;
  final String amount;
  final bool income;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: c.tintBlue,
            borderRadius: BorderRadius.circular(FreevaRadius.sm),
          ),
          child: Icon(icon, size: 18, color: c.tintBlueFg),
        ),
        const SizedBox(width: FreevaSpace.s3),
        Expanded(child: Text(title, style: FreevaTypography.body)),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 130),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              amount,
              style: FreevaTypography.moneyL.copyWith(
                fontSize: 15,
                color: income ? c.moneyIncome : c.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
