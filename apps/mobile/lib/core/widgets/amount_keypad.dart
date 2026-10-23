import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';
import 'press_scale.dart';

/// Freeva's own amount keypad (no system keyboard): 1–9, `000`, 0, delete.
/// Keys give a light haptic. The caller owns the value and the 13-digit cap.
class AmountKeypad extends StatelessWidget {
  const AmountKeypad({
    required this.onDigits,
    required this.onDelete,
    this.filled = true,
    super.key,
  });

  /// White keys (component sheet) or flat keys on the page background
  /// (record screen).
  final bool filled;

  /// Receives "0"–"9" or "000".
  final ValueChanged<String> onDigits;
  final VoidCallback onDelete;

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
            label: S.of(context).keypadDelete,
            icon: LucideIcons.delete,
            onTap: onDelete,
          )
        : _Key(label: key, filled: filled, onTap: () => onDigits(key));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < _keys.length; r += 3) ...[
          if (r > 0) const SizedBox(height: 6),
          SizedBox(
            height: FreevaSize.button,
            child: Row(
              children: [
                for (var i = r; i < r + 3; i++) ...[
                  if (i > r) const SizedBox(width: 6),
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
    this.icon,
    this.filled = true,
  });

  final bool filled;

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
          borderRadius: BorderRadius.circular(FreevaRadius.md),
          child: InkWell(
            borderRadius: BorderRadius.circular(FreevaRadius.md),
            splashFactory: NoSplash.splashFactory,
            highlightColor: c.bgSubtle,
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            child: Center(
              child: icon != null
                  ? Icon(icon, size: FreevaSize.icon, color: c.textPrimary)
                  : Text(
                      label,
                      style: FreevaTypography.moneyL.copyWith(
                        fontSize: label.length > 1 ? 16 : 22,
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
