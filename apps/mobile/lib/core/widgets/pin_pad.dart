import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';
import 'press_scale.dart';

/// Six dots for a PIN: filled for each digit typed. Spoken as a count so the
/// digits are never read out.
class PinDots extends StatelessWidget {
  const PinDots({required this.length, this.error = false, super.key});

  static const total = 6;

  final int length;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: S.of(context).pinDigitsEntered(length, total),
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < total; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9),
                child: AnimatedContainer(
                  duration: FreevaMotion.fast,
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < length
                        ? (error ? c.statusDanger : c.actionInk)
                        : Colors.transparent,
                    border: i < length
                        ? null
                        : Border.all(
                            color: error ? c.statusDanger : c.borderDefault,
                            width: 1.5,
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Number keys 1–9, 0 and delete in a 3×4 grid. [leading] fills the bottom
/// left slot (Face ID on the lock screen); it is empty otherwise.
class PinKeypad extends StatelessWidget {
  const PinKeypad({
    required this.onDigit,
    required this.onDelete,
    this.leading,
    super.key,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final rows = [
      for (var r = 0; r < 3; r++) [for (var i = 1; i <= 3; i++) '${r * 3 + i}'],
    ];
    Widget row(List<Widget> keys) => SizedBox(
      height: 64,
      child: Row(children: [for (final key in keys) Expanded(child: key)]),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final digits in rows)
          row([
            for (final d in digits) PinKey(label: d, onTap: () => onDigit(d)),
          ]),
        row([
          leading ?? const SizedBox.shrink(),
          PinKey(label: '0', onTap: () => onDigit('0')),
          PinKey(
            label: s.keypadDelete,
            icon: LucideIcons.delete,
            onTap: onDelete,
          ),
        ]),
      ],
    );
  }
}

/// One round key. With [icon] it shows the icon and speaks [label].
class PinKey extends StatelessWidget {
  const PinKey({
    required this.label,
    required this.onTap,
    this.icon,
    super.key,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: PressScale(
        child: Semantics(
          button: true,
          label: label,
          excludeSemantics: true,
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              splashFactory: NoSplash.splashFactory,
              highlightColor: c.bgSubtle,
              onTap: () {
                HapticFeedback.lightImpact();
                onTap();
              },
              child: SizedBox.square(
                dimension: 60,
                child: Center(
                  child: icon != null
                      ? Icon(icon, size: FreevaSize.icon, color: c.textPrimary)
                      : Text(
                          label,
                          style: FreevaTypography.moneyL.copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.w500,
                            color: c.textPrimary,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
