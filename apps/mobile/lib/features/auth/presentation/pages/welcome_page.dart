import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/balance_card.dart';
import '../../../../core/widgets/freeva_button.dart';
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
    final title = FreevaTypography.titleXl.copyWith(
      fontSize: 34,
      height: 40 / 34,
      letterSpacing: -1,
      color: c.textPrimary,
    );
    return AuthScaffold(
      topGap: 0,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FreevaButton(
            label: s.welcomeStart,
            size: FreevaButtonSize.l,
            expand: true,
            onPressed: () => model.leaveWelcome(AuthStep.signUp),
          ),
          const SizedBox(height: FreevaSpace.s1),
          AuthSwitchLink(
            prompt: s.authHaveAccount,
            action: s.authLogin,
            actionColor: c.textLink,
            onTap: () => model.leaveWelcome(AuthStep.login),
          ),
        ],
      ),
      children: [
        const _Hero(),
        const SizedBox(height: 28),
        Semantics(
          header: true,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '${s.welcomeTitleLine1}\n'),
                TextSpan(
                  text: s.welcomeTitleLine2,
                  style: TextStyle(color: c.textLink),
                ),
              ],
            ),
            style: title,
          ),
        ),
        const SizedBox(height: FreevaSpace.s3),
        Text(
          s.welcomeSub,
          style: FreevaTypography.body.copyWith(
            fontSize: 16,
            height: 1.5,
            color: c.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Decorative piece of the app: a balance card on a soft disc, two floating
/// transaction rows and the + button. Hidden from screen readers; the
/// numbers are only an example.
class _Hero extends StatelessWidget {
  const _Hero();

  static const double _height = 400;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    return ExcludeSemantics(
      child: SizedBox(
        height: _height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 0,
              left: -100,
              right: -100,
              child: Center(
                child: Container(
                  width: 340,
                  height: 340,
                  decoration: BoxDecoration(
                    color: c.bgSubtle,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 62,
              left: 40,
              right: 40,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    FreevaComponent.balanceCardRadius,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      offset: Offset(0, 16),
                      blurRadius: 40,
                      color: Color(0x1F22283A),
                    ),
                  ],
                ),
                child: WashSurface(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.welcomeSampleBalance,
                        style: FreevaTypography.bodyS.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: c.textOnWash,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Decorative sample: scaling it down is fine here.
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(text: '24.600.000 '),
                              TextSpan(
                                text: '₫',
                                style: FreevaTypography.body.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0,
                                  color: c.textOnWash,
                                ),
                              ),
                            ],
                          ),
                          style: FreevaTypography.moneyL.copyWith(
                            height: 32 / 28,
                            letterSpacing: -0.8,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 184,
              left: 4,
              child: _FloatingRow(
                icon: LucideIcons.utensils,
                tint: c.tintBlue,
                tintFg: c.tintBlueFg,
                title: s.welcomeSampleFood,
                amount: '−65.000',
                amountColor: c.textPrimary,
              ),
            ),
            Positioned(
              top: 258,
              right: 2,
              child: _FloatingRow(
                icon: LucideIcons.arrowUp,
                tint: c.tintGreen,
                tintFg: c.tintGreenFg,
                title: s.welcomeSampleSalary,
                amount: '+18.500.000',
                amountColor: c.moneyIncome,
              ),
            ),
            Positioned(
              top: 330,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: FreevaSize.fab,
                  height: FreevaSize.fab,
                  decoration: BoxDecoration(
                    color: c.actionPrimary,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(spreadRadius: 8, color: Color(0x265680E9)),
                    ],
                  ),
                  child: Icon(LucideIcons.plus, color: c.textOnAction),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// White pill row floating over the disc: tinted icon, name, amount.
class _FloatingRow extends StatelessWidget {
  const _FloatingRow({
    required this.icon,
    required this.tint,
    required this.tintFg,
    required this.title,
    required this.amount,
    required this.amountColor,
  });

  final IconData icon;
  final Color tint;
  final Color tintFg;
  final String title;
  final String amount;
  final Color amountColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = FreevaTypography.body.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: c.textPrimary,
    );
    return Container(
      height: 56,
      padding: const EdgeInsets.fromLTRB(10, 0, 14, 0),
      decoration: BoxDecoration(
        color: c.bgSurface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: FreevaElevation.s2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
            child: Icon(icon, size: 17, color: tintFg),
          ),
          const SizedBox(width: 10),
          Text(title, style: text),
          const SizedBox(width: 18),
          Text(
            amount,
            style: text.copyWith(
              fontWeight: FontWeight.w600,
              color: amountColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
