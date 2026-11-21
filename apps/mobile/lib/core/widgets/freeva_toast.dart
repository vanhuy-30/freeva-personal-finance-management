import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';

OverlayEntry? _current;

/// Ink toast at the top of the screen, under the status bar: radius 16, at
/// least 52 high, 18 mint icon, plain blue action text. 4 s, or 6 s with an
/// action (usually "Hoàn tác"). One at a time: a new toast replaces the
/// current one. `success` shows a check when no [icon] is given.
///
/// Drawn in the root overlay, not a SnackBar: it does not depend on the
/// screen's Scaffold (a bottom bar or a sheet cannot push it off screen) and
/// survives the screen closing right after the call.
void showFreevaToast(
  BuildContext context, {
  required String message,
  IconData? icon,
  bool success = false,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  _current?.remove();
  late final OverlayEntry entry;
  void close() {
    entry.remove();
    if (identical(_current, entry)) _current = null;
  }

  entry = OverlayEntry(
    builder: (context) => _Toast(
      message: message,
      glyph: icon ?? (success ? LucideIcons.check : null),
      actionLabel: actionLabel,
      onAction: onAction,
      duration: actionLabel == null
          ? FreevaMotion.toast
          : FreevaMotion.toastWithAction,
      onClosed: close,
    ),
  );
  _current = entry;
  overlay.insert(entry);
}

class _Toast extends StatefulWidget {
  const _Toast({
    required this.message,
    required this.glyph,
    required this.actionLabel,
    required this.onAction,
    required this.duration,
    required this.onClosed,
  });

  final String message;
  final IconData? glyph;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration duration;
  final VoidCallback onClosed;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late final AnimationController _slide = AnimationController(
    vsync: this,
    duration: FreevaMotion.fast,
  );
  Timer? _timer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _slide.forward();
    _timer = Timer(widget.duration, _dismiss);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _slide.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (_closing) return;
    _closing = true;
    _timer?.cancel();
    await _slide.reverse();
    widget.onClosed();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final top = MediaQuery.paddingOf(context).top + FreevaSpace.s2;
    final curve = CurvedAnimation(parent: _slide, curve: FreevaMotion.standard);
    return Positioned(
      top: top,
      left: context.screenMargin,
      right: context.screenMargin,
      child: FadeTransition(
        opacity: curve,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, -0.4),
            end: Offset.zero,
          ).animate(curve),
          child: Semantics(
            liveRegion: true,
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onVerticalDragEnd: (d) {
                  if ((d.primaryVelocity ?? 0) < 0) _dismiss();
                },
                child: Container(
                  constraints: const BoxConstraints(minHeight: 52),
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 6, 0),
                  decoration: BoxDecoration(
                    color: c.toastBg,
                    borderRadius: BorderRadius.circular(FreevaRadius.md),
                    boxShadow: FreevaElevation.toast,
                  ),
                  child: Row(
                    children: [
                      if (widget.glyph != null) ...[
                        Icon(
                          widget.glyph,
                          size: FreevaSize.iconSm,
                          color: c.toastIcon,
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: FreevaSpace.s2,
                          ),
                          child: Text(
                            widget.message,
                            style: FreevaTypography.bodyM.copyWith(
                              fontWeight: FontWeight.w500,
                              color: c.toastFg,
                            ),
                          ),
                        ),
                      ),
                      if (widget.actionLabel != null) ...[
                        const SizedBox(width: 10),
                        TextButton(
                          onPressed: () {
                            _dismiss();
                            widget.onAction?.call();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: c.toastAction,
                            backgroundColor: Colors.transparent,
                            minimumSize: const Size(
                              FreevaSize.touch,
                              FreevaSize.touch,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            textStyle: FreevaTypography.bodyM.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: Text(widget.actionLabel!),
                        ),
                      ],
                    ],
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
