import 'package:flutter/material.dart';

import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';

/// One button behind a [SwipeActions] row.
class SwipeAction {
  const SwipeAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;

  /// Runs after the row closes. Null: shown dimmed and does nothing.
  final VoidCallback? onTap;

  /// Delete-style: error colours instead of the neutral wash.
  final bool danger;
}

/// A list row that slides left to show quick actions (Ẩn, Xoá), for people
/// who would rather not open the item first. Only one row stays open: opening
/// another, tapping the open row, or scrolling closes it.
class SwipeActions extends StatefulWidget {
  const SwipeActions({required this.child, required this.actions, super.key});

  final Widget child;
  final List<SwipeAction> actions;

  /// Width of one action button.
  static const actionWidth = 72.0;

  @override
  State<SwipeActions> createState() => _SwipeActionsState();
}

class _SwipeActionsState extends State<SwipeActions>
    with SingleTickerProviderStateMixin {
  /// The row that is open right now, across the whole app.
  static final _open = ValueNotifier<Object?>(null);

  late final AnimationController _slide = AnimationController(
    vsync: this,
    duration: FreevaMotion.fast,
  );

  double get _extent => SwipeActions.actionWidth * widget.actions.length;

  @override
  void initState() {
    super.initState();
    _open.addListener(_otherOpened);
  }

  void _otherOpened() {
    if (_open.value != this) _close();
  }

  @override
  void dispose() {
    _open.removeListener(_otherOpened);
    if (_open.value == this) _open.value = null;
    _slide.dispose();
    super.dispose();
  }

  void _close() {
    if (_slide.value > 0) _slide.reverse();
    if (_open.value == this) _open.value = null;
  }

  void _openRow() {
    _slide.forward();
    _open.value = this;
  }

  void _drag(DragUpdateDetails d) {
    // Left is negative in LTR, positive in RTL: the actions sit at the end.
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final delta = (rtl ? d.delta.dx : -d.delta.dx) / _extent;
    _slide.value = (_slide.value + delta).clamp(0.0, 1.0);
  }

  void _dragEnd(DragEndDetails d) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final v = (rtl
        ? d.velocity.pixelsPerSecond.dx
        : -d.velocity.pixelsPerSecond.dx);
    if (v > 300 || (v > -300 && _slide.value > .4)) {
      _openRow();
    } else {
      _close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ClipRect(
      child: GestureDetector(
        onHorizontalDragUpdate: _drag,
        onHorizontalDragEnd: _dragEnd,
        child: Stack(
          children: [
            // The buttons, under the row, at the end edge.
            Positioned.fill(
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: SizedBox(
                  width: _extent,
                  child: Row(
                    children: [
                      for (final a in widget.actions)
                        Expanded(
                          child: _Button(
                            action: a,
                            onPressed: () {
                              _close();
                              a.onTap?.call();
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _slide,
              builder: (context, child) {
                final open = _slide.value > 0;
                final rtl = Directionality.of(context) == TextDirection.rtl;
                return Transform.translate(
                  offset: Offset((rtl ? 1 : -1) * _slide.value * _extent, 0),
                  // While open, a tap on the row closes it instead of
                  // opening the item.
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: open ? _close : null,
                    child: IgnorePointer(ignoring: open, child: child),
                  ),
                );
              },
              child: ColoredBox(color: c.bgSurface, child: widget.child),
            ),
          ],
        ),
      ),
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({required this.action, required this.onPressed});

  final SwipeAction action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = action.onTap != null;
    final bg = action.danger ? c.statusDangerBg : c.bgSubtle;
    final fg = !enabled
        ? c.textDisabled
        : action.danger
        ? c.actionDanger
        : c.textOnWash;
    return Semantics(
      button: true,
      enabled: enabled,
      label: action.label,
      excludeSemantics: true,
      onTap: enabled ? onPressed : null,
      child: Material(
        color: bg,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(action.icon, size: FreevaSize.iconSm, color: fg),
              const SizedBox(height: 4),
              Text(
                action.label,
                style: FreevaTypography.label.copyWith(
                  fontWeight: FontWeight.w500,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
