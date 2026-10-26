import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';
import 'press_scale.dart';

enum SocialProvider { google, apple, email }

/// "Tiếp tục với Google / Apple / email": height 54, no border. Google sits on
/// `bg.subtle`, Apple on `action.ink`.
class SocialSignInButton extends StatelessWidget {
  const SocialSignInButton({
    required this.provider,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final SocialProvider provider;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final apple = provider == SocialProvider.apple;
    final bg = apple ? c.actionInk : c.bgSubtle;
    final fg = apple ? c.textOnInk : c.textPrimary;
    return PressScale(
      enabled: onPressed != null,
      child: Material(
        color: bg,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 54),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: FreevaSpace.s5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  switch (provider) {
                    SocialProvider.apple => Icon(
                      Icons.apple,
                      size: 22,
                      color: fg,
                    ),
                    SocialProvider.email => Icon(
                      LucideIcons.mail,
                      size: 20,
                      color: fg,
                    ),
                    SocialProvider.google => const SizedBox.square(
                      dimension: 20,
                      child: CustomPaint(painter: _GoogleMark()),
                    ),
                  },
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      label,
                      style: FreevaTypography.titleM.copyWith(
                        fontSize: 16,
                        color: fg,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The four-colour "G" drawn from arcs; brand colours are fixed by Google.
class _GoogleMark extends CustomPainter {
  const _GoogleMark();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.2;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.width / 2 - stroke / 2,
    );
    Paint paint(Color color) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = color;
    double deg(double d) => d * math.pi / 180;
    canvas
      ..drawArc(rect, deg(-45), deg(90), false, paint(const Color(0xFF4285F4)))
      ..drawArc(rect, deg(45), deg(90), false, paint(const Color(0xFF34A853)))
      ..drawArc(rect, deg(135), deg(65), false, paint(const Color(0xFFFBBC05)))
      ..drawArc(rect, deg(200), deg(115), false, paint(const Color(0xFFEA4335)))
      ..drawLine(
        size.center(Offset.zero),
        Offset(size.width - stroke * 0.1, size.height / 2),
        paint(const Color(0xFF4285F4)),
      );
  }

  @override
  bool shouldRepaint(_GoogleMark oldDelegate) => false;
}
