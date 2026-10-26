import 'package:flutter/material.dart';

import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';
import 'f_strokes_painter.dart';

/// 64 tile with the animated F strokes.
class FStrokesMark extends StatefulWidget {
  const FStrokesMark({super.key});

  @override
  State<FStrokesMark> createState() => _FStrokesMarkState();
}

class _FStrokesMarkState extends State<FStrokesMark>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ExcludeSemantics(
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: c.tintBlue,
          borderRadius: BorderRadius.circular(22),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: FStrokesPainter(
              colors: [c.data1, FreevaPrimitive.cyan300, c.data2],
              t: _controller.value,
            ),
          ),
        ),
      ),
    );
  }
}

/// Static 120×112 empty-state illustration (boards TxNoResult, RepEmpty).
class FStrokesIllustration extends StatelessWidget {
  const FStrokesIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ExcludeSemantics(
      child: CustomPaint(
        size: const Size(120, 112),
        painter: FStrokesIllustrationPainter(
          ground: c.borderDivider,
          stem: c.actionPrimary,
          top: FreevaPrimitive.blue200,
          middle: FreevaPrimitive.violet200,
        ),
      ),
    );
  }
}
