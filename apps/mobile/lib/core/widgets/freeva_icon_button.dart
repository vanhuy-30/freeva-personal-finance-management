import 'package:flutter/material.dart';

import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';
import 'press_scale.dart';

enum FreevaIconButtonKind {
  /// 44, white with a hairline border. Top bars.
  bar,

  /// 36 on a card, white 75%; the touch area stays 44.
  onCard,

  /// 40 white circle with a hairline border, 18 glyph (− / + steppers).
  /// Disabled greys the border and the glyph.
  stepper,

  /// 36 subtle-grey circle, no border, 16 glyph (secondary actions in rows).
  subtle,
}

class FreevaIconButton extends StatelessWidget {
  const FreevaIconButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.kind = FreevaIconButtonKind.bar,
    this.iconSize,
    super.key,
  });

  final IconData icon;

  /// Screen-reader label and long-press tooltip. Required for every icon button.
  final String label;
  final VoidCallback? onPressed;
  final FreevaIconButtonKind kind;

  /// Glyph size. Defaults to 20 (bar, onCard), 18 (stepper), 16 (subtle).
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onPressed != null;
    final (double size, Color bg, Color? border, double glyph) = switch (kind) {
      FreevaIconButtonKind.bar => (
        FreevaSize.iconButton,
        c.bgSurface,
        c.borderDivider,
        FreevaSize.iconInline,
      ),
      FreevaIconButtonKind.onCard => (
        FreevaSize.iconButtonS,
        c.bgSurface.withValues(alpha: .75),
        null,
        FreevaSize.iconInline,
      ),
      FreevaIconButtonKind.stepper => (
        FreevaSize.buttonXs,
        c.bgSurface,
        enabled ? c.borderDivider : c.bgSubtle,
        FreevaSize.iconSm,
      ),
      FreevaIconButtonKind.subtle => (
        FreevaSize.iconButtonS,
        c.bgSubtle,
        null,
        FreevaSize.iconChip,
      ),
    };
    final fg = enabled
        ? c.textPrimary
        : kind == FreevaIconButtonKind.stepper
        ? c.borderStrong
        : c.textDisabled;
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: label,
        child: PressScale(
          enabled: enabled,
          child: InkResponse(
            onTap: onPressed,
            radius: FreevaSize.touch / 2,
            highlightShape: BoxShape.circle,
            splashFactory: NoSplash.splashFactory,
            child: SizedBox.square(
              dimension: FreevaSize.touch,
              child: Center(
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: bg,
                    border: border == null ? null : Border.all(color: border),
                  ),
                  child: Icon(icon, size: iconSize ?? glyph, color: fg),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
