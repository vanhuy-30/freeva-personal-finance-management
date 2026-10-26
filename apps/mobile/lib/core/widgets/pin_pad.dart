import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

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
                padding: const EdgeInsets.symmetric(horizontal: 7),
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
                            color: error ? c.statusDanger : c.borderStrong,
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

/// Number keys 1–9, 0 and delete in a centred 3×4 grid of 76-wide keys
/// with 28 between columns. [leading] fills the bottom left slot (Face ID on
/// the lock screen); it is empty otherwise. Defaults follow the lock screen
/// (keys 64, rows 10 apart); PIN setup uses 60 / 6.
class PinKeypad extends StatelessWidget {
  const PinKeypad({
    required this.onDigit,
    required this.onDelete,
    this.leading,
    this.keyHeight = 64,
    this.rowGap = 10,
    super.key,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final Widget? leading;

  /// Height of each key.
  final double keyHeight;

  /// Gap between rows.
  final double rowGap;

  static const double _keyWidth = 76;
  static const double _columnGap = 28;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final rows = [
      for (var r = 0; r < 3; r++) [for (var i = 1; i <= 3; i++) '${r * 3 + i}'],
    ];
    // Loose flex shares: full size when there is room, and keys and gaps
    // shrink together on narrow screens (320 at large text).
    Widget row(List<Widget> keys) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < keys.length; i++) ...[
          if (i > 0)
            const Flexible(flex: 28, child: SizedBox(width: _columnGap)),
          Flexible(
            flex: 76,
            child: SizedBox(
              width: _keyWidth,
              height: keyHeight,
              child: keys[i],
            ),
          ),
        ],
      ],
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final digits in rows) ...[
          row([
            for (final d in digits) PinKey(label: d, onTap: () => onDigit(d)),
          ]),
          SizedBox(height: rowGap),
        ],
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

/// One pill key filling its grid cell: digits 28/500, icons 26. With [icon]
/// it shows the icon and speaks [label].
class PinKey extends StatelessWidget {
  const PinKey({
    required this.label,
    required this.onTap,
    this.icon,
    this.iconColor,
    this.iconSize = 26,
    super.key,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  /// Glyph colour; default `text.primary` (Face ID uses `action.primary`).
  final Color? iconColor;

  /// Glyph size (Face ID uses 30).
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PressScale(
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: Colors.transparent,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            customBorder: const StadiumBorder(),
            splashFactory: NoSplash.splashFactory,
            highlightColor: c.bgSubtle,
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: FreevaSize.touch,
                minHeight: FreevaSize.touch,
              ),
              child: Center(
                child: icon != null
                    ? Icon(
                        icon,
                        size: iconSize,
                        color: iconColor ?? c.textPrimary,
                      )
                    : Text(
                        label,
                        style: FreevaTypography.moneyL.copyWith(
                          fontSize: 28,
                          height: 1.2,
                          letterSpacing: 0,
                          fontWeight: FontWeight.w500,
                          color: c.textPrimary,
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
