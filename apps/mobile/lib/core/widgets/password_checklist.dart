import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../features/auth/domain/password_check.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';

/// Three-step strength bar with its label. Hidden until something is typed.
class PasswordStrengthBar extends StatelessWidget {
  const PasswordStrengthBar({required this.check, super.key});

  final PasswordCheck check;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = S.of(context);
    final level = check.strength;
    if (level == 0) return const SizedBox.shrink();
    final color = level == 1 ? c.statusWarning : c.statusSuccess;
    final label = switch (level) {
      1 => s.passwordWeak,
      2 => s.passwordGood,
      _ => s.passwordStrong,
    };
    return Semantics(
      container: true,
      liveRegion: true,
      label: label,
      child: ExcludeSemantics(
        child: Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: FreevaSpace.s1),
              Expanded(
                child: AnimatedContainer(
                  duration: FreevaMotion.fast,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i < level ? color : c.bgTrack,
                    borderRadius: BorderRadius.circular(FreevaRadius.full),
                  ),
                ),
              ),
            ],
            const SizedBox(width: FreevaSpace.s3),
            Text(label, style: FreevaTypography.bodyS.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

/// Conditions that tick as the password is typed. The symbol line is a tip,
/// so it never blocks. Read aloud on change (live region).
class PasswordChecklist extends StatelessWidget {
  const PasswordChecklist({required this.check, super.key});

  final PasswordCheck check;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Semantics(
      container: true,
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Rule(s.passwordRuleLength, check.longEnough),
          _Rule(s.passwordRuleLetterDigit, check.letterAndDigit),
          _Rule(s.passwordRuleSymbol, check.hasSymbol),
          _Rule(s.passwordRuleMatch, check.matches),
        ],
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule(this.text, this.met);

  final String text;
  final bool met;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = S.of(context);
    return Semantics(
      label: '$text, ${met ? s.passwordRuleMet : s.passwordRuleNotMet}',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: FreevaMotion.fast,
                width: 18,
                height: 18,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: met ? c.statusSuccessBg : Colors.transparent,
                  border: met
                      ? null
                      : Border.all(color: c.borderDefault, width: 1.5),
                ),
                child: met
                    ? Icon(LucideIcons.check, size: 12, color: c.statusSuccess)
                    : null,
              ),
              const SizedBox(width: FreevaSpace.s3),
              Expanded(
                child: Text(
                  text,
                  style: FreevaTypography.bodyS.copyWith(
                    fontSize: 13,
                    color: met ? c.textPrimary : c.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
