import 'package:flutter/material.dart';

import '../../features/auth/domain/password_check.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';
import 'check_mark.dart';

/// Three-step strength bar with its label (13/600, 10 after the bar).
/// Hidden until something is typed.
class PasswordStrengthBar extends StatelessWidget {
  const PasswordStrengthBar({
    required this.check,
    this.segmentHeight = 5,
    super.key,
  });

  final PasswordCheck check;

  /// Height of each segment (reset password uses 6).
  final double segmentHeight;

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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: FreevaSpace.s1),
          child: Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: FreevaSpace.s1),
                Expanded(
                  child: AnimatedContainer(
                    duration: FreevaMotion.fast,
                    height: segmentHeight,
                    decoration: BoxDecoration(
                      color: i < level ? color : c.borderDefault,
                      borderRadius: BorderRadius.circular(FreevaRadius.full),
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 10),
              Text(
                label,
                style: FreevaTypography.bodyS.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Conditions that tick as the password is typed: 18 px marks, rows 8
/// apart (26 pitch), 4 px side inset. The symbol line is a tip, so it never
/// blocks. Read aloud on change (live region).
class PasswordChecklist extends StatelessWidget {
  const PasswordChecklist({required this.check, super.key});

  final PasswordCheck check;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Semantics(
      container: true,
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: FreevaSpace.s1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: FreevaSpace.s2,
          children: [
            _Rule(s.passwordRuleLength, check.longEnough),
            _Rule(s.passwordRuleLetterDigit, check.letterAndDigit),
            _Rule(s.passwordRuleSymbol, check.hasSymbol),
            _Rule(s.passwordRuleMatch, check.matches),
          ],
        ),
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
        child: Row(
          children: [
            AnimatedContainer(
              duration: FreevaMotion.fast,
              width: 18,
              height: 18,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: met ? c.statusSuccessBg : Colors.transparent,
                border: met
                    ? null
                    : Border.all(color: c.borderStrong, width: 1.5),
              ),
              child: met ? CheckMark(size: 11, color: c.statusSuccess) : null,
            ),
            const SizedBox(width: FreevaSpace.s2),
            Expanded(
              child: Text(
                text,
                style: FreevaTypography.bodyS.copyWith(
                  height: 18 / 13,
                  color: met ? c.textPrimary : c.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
