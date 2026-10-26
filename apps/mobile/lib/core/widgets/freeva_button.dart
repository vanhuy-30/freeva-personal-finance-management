import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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
    final iconSize = switch (size) {
      FreevaButtonSize.l => FreevaSize.iconInline,
      FreevaButtonSize.m || FreevaButtonSize.dialog => FreevaSize.iconSm,
      FreevaButtonSize.s ||
      FreevaButtonSize.xs ||
      FreevaButtonSize.compact => FreevaSize.iconChip,
    };
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
    Widget button = TextButton(
      onPressed: loading ? () {} : onPressed,
      style: style,
      child: Semantics(
        label: loading ? label : null,
        child: ExcludeSemantics(excluding: loading, child: content),
      ),
    );
    if (expand) button = SizedBox(width: double.infinity, child: button);
    if (size == FreevaButtonSize.compact) {
      button = _TouchTarget(child: button);
    }
    return PressScale(enabled: onPressed != null && !loading, child: button);
  }
}

/// Lays a smaller button out in a 44-high box and sends taps anywhere in that
/// box to the button, so a 36 visual keeps a 44 touch target.
class _TouchTarget extends SingleChildRenderObjectWidget {
  const _TouchTarget({required Widget super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderTouchTarget();
}

class _RenderTouchTarget extends RenderShiftedBox {
  _RenderTouchTarget() : super(null);

  @override
  void performLayout() {
    final child = this.child!;
    child.layout(constraints, parentUsesSize: true);
    size = constraints.constrain(
      Size(child.size.width, math.max(child.size.height, FreevaSize.touch)),
    );
    (child.parentData! as BoxParentData).offset = Alignment.center.alongOffset(
      Offset(size.width - child.size.width, size.height - child.size.height),
    );
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (super.hitTest(result, position: position)) return true;
    if (!size.contains(position)) return false;
    final center = child!.size.center(Offset.zero);
    return result.addWithRawTransform(
      transform: MatrixUtils.forceToPoint(center),
      position: center,
      hitTest: (result, position) => child!.hitTest(result, position: center),
    );
  }
}
