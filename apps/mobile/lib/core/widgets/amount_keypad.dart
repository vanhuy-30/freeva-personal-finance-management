import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';
import 'press_scale.dart';

/// Freeva's own amount keypad (no system keyboard): 1–9, `000`, 0, delete.
/// Keys give a light haptic. The caller owns the value and the 13-digit cap.
/// Defaults follow the record screen (keys 54, gap 2, radius 16, digits 24,
/// `000` 18, delete 24); onboarding budget uses 50 / 4 / 14 / 22 / 17 / 22,
/// transfer 50 high.
class AmountKeypad extends StatelessWidget {
  const AmountKeypad({
    required this.onDigits,
    required this.onDelete,
    this.filled = true,
    this.keyHeight = 54,
    this.gap = 2,
    this.radius = FreevaRadius.md,
    this.digitSize = 24,
    this.tripleZeroSize = 18,
    this.deleteIconSize = FreevaSize.icon,
    super.key,
  });

  /// White keys (component sheet) or flat keys on the page background
  /// (record screen).
  final bool filled;

  /// Receives "0"–"9" or "000".
  final ValueChanged<String> onDigits;
  final VoidCallback onDelete;

  /// Height of each key row.
  final double keyHeight;

  /// Gap between keys, both ways.
  final double gap;

  /// Key corner radius (pressed highlight).
  final double radius;

  /// Font size of 0–9.
  final double digitSize;

  /// Font size of `000`.
  final double tripleZeroSize;

  /// Size of the delete glyph.
  final double deleteIconSize;

  static const _keys = [
    '1', '2', '3', '4', '5', '6', '7', '8', '9', '000', '0', '', //
  ];

  @override
  Widget build(BuildContext context) {
    // Rows, not a GridView: a shrink-wrapped grid cannot be measured by
    // screens that size their content to the available height.
    Widget keyFor(String key) => key.isEmpty
        ? _Key(
            filled: filled,
            radius: radius,
            label: S.of(context).keypadDelete,
            icon: LucideIcons.delete,
            size: deleteIconSize,
            onTap: onDelete,
          )
        : _Key(
            label: key,
            filled: filled,
            radius: radius,
            size: key.length > 1 ? tripleZeroSize : digitSize,
            onTap: () => onDigits(key),
          );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < _keys.length; r += 3) ...[
          if (r > 0) SizedBox(height: gap),
          SizedBox(
            height: keyHeight,
            child: Row(
              children: [
                for (var i = r; i < r + 3; i++) ...[
                  if (i > r) SizedBox(width: gap),
                  Expanded(child: keyFor(_keys[i])),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    required this.label,
    required this.onTap,
    required this.radius,
    required this.size,
    this.icon,
    this.filled = true,
  });

  final bool filled;
  final double radius;

  /// Glyph or font size.
  final double size;

  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PressScale(
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: filled ? c.bgSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(radius),
          child: InkWell(
            borderRadius: BorderRadius.circular(radius),
            splashFactory: NoSplash.splashFactory,
            highlightColor: c.bgSubtle,
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            child: Center(
              child: icon != null
                  ? Icon(icon, size: size, color: c.textPrimary)
                  : Text(
                      label,
                      style: FreevaTypography.moneyL.copyWith(
                        fontSize: size,
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
    );
  }
}
