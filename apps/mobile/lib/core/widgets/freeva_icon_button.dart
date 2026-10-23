import 'package:flutter/material.dart';

import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';
import 'press_scale.dart';

enum FreevaIconButtonKind {
  /// 44, white with a hairline border. Top bars.
  bar,

  /// 36 on a card, white 75%; the touch area stays 44.
  onCard,
}

class FreevaIconButton extends StatelessWidget {
  const FreevaIconButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.kind = FreevaIconButtonKind.bar,
    super.key,
  });

  final IconData icon;

  /// Screen-reader label and long-press tooltip. Required for every icon button.
  final String label;
  final VoidCallback? onPressed;
  final FreevaIconButtonKind kind;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bar = kind == FreevaIconButtonKind.bar;
    final size = bar ? FreevaSize.iconButton : FreevaSize.iconButtonS;
    final enabled = onPressed != null;
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
                    color: bar
                        ? c.bgSurface
                        : c.bgSurface.withValues(alpha: .75),
                    border: bar ? Border.all(color: c.borderDivider) : null,
                  ),
                  child: Icon(
                    icon,
                    size: FreevaSize.iconInline,
                    color: enabled ? c.textPrimary : c.textDisabled,
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
