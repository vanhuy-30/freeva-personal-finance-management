import 'package:flutter/material.dart';

import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';
import 'freeva_button_style.dart';
import 'press_scale.dart';

export 'freeva_button_style.dart' show FreevaButtonSize, FreevaButtonVariant;

/// Freeva button. One primary per screen; `ink` for the next step in a flow.
/// `loading` keeps the size and blocks repeated taps.
class FreevaButton extends StatelessWidget {
  const FreevaButton({
    required this.label,
    required this.onPressed,
    this.variant = FreevaButtonVariant.primary,
    this.size = FreevaButtonSize.m,
    this.icon,
    this.loading = false,
    this.expand = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final FreevaButtonVariant variant;
  final FreevaButtonSize size;
  final IconData? icon;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = freevaButtonStyle(c, variant, size);
    final small = size == FreevaButtonSize.s || size == FreevaButtonSize.xs;
    final iconSize = small ? FreevaSize.iconChip : FreevaSize.iconInline;
    final content = loading
        ? SizedBox.square(
            dimension: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: style.foregroundColor?.resolve({}),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: iconSize),
                const SizedBox(width: FreevaSpace.s2),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
    final button = TextButton(
      onPressed: loading ? () {} : onPressed,
      style: style,
      child: Semantics(
        label: loading ? label : null,
        child: ExcludeSemantics(excluding: loading, child: content),
      ),
    );
    return PressScale(
      enabled: onPressed != null && !loading,
      child: expand ? SizedBox(width: double.infinity, child: button) : button,
    );
  }
}
