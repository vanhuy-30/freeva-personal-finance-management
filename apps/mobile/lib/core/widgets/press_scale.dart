import 'package:flutter/material.dart';

import '../theme/tokens.g.dart';

/// Shrinks its child to `pressedScale` while a pointer is down (100 ms).
/// Listens to raw pointers, so the child's own gestures still win.
class PressScale extends StatefulWidget {
  const PressScale({required this.child, this.enabled = true, super.key});

  final Widget child;
  final bool enabled;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  var _down = false;

  void _set(bool down) {
    if (!widget.enabled || _down == down) return;
    setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down && !reduce ? FreevaMotion.pressedScale : 1,
        duration: FreevaMotion.press,
        curve: FreevaMotion.standard,
        child: widget.child,
      ),
    );
  }
}
