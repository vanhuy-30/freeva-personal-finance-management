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
    super.key,
  });

  /// Receives "0"–"9" or "000".
  final ValueChanged<String> onDigits;
  final VoidCallback onDelete;

  static const _keys = [
    '1', '2', '3', '4', '5', '6', '7', '8', '9', '000', '0', '', //
  ];

  @override
  Widget build(BuildContext context) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        mainAxisExtent: FreevaSize.button,
      ),
      children: [
        for (final key in _keys)
          key.isEmpty
              ? _Key(
                  label: S.of(context).keypadDelete,
                  icon: LucideIcons.delete,
                  onTap: onDelete,
                )
              : _Key(label: key, onTap: () => onDigits(key)),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.onTap, this.icon});

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
          color: c.bgSurface,
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
