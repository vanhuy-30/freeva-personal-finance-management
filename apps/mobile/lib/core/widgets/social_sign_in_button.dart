import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

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
                    SocialProvider.apple => SizedBox(
                      width: 18,
                      height: 20,
                      child: CustomPaint(painter: _AppleMark(fg)),
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

/// Google's four-colour "G" (paths from the sign-in board, 48 grid); brand
/// colours are fixed by Google.
class _GoogleMark extends CustomPainter {
  const _GoogleMark();

  static final _blue = Path()
    ..moveTo(45.1, 24.5)
    ..cubicTo(45.1, 22.9, 45, 21.4, 44.7, 20)
    ..lineTo(24, 20)
    ..lineTo(24, 28.5)
    ..lineTo(35.8, 28.5)
    ..cubicTo(35.3, 31.3, 33.7, 33.6, 31.4, 35.2)
    ..lineTo(31.4, 40.8)
    ..lineTo(38.5, 40.8)
    ..cubicTo(42.7, 37, 45.1, 31.3, 45.1, 24.5)
    ..close();
  static final _green = Path()
    ..moveTo(24, 46)
    ..cubicTo(29.9, 46, 34.9, 44, 38.5, 40.7)
    ..lineTo(31.4, 35.1)
    ..cubicTo(29.4, 36.4, 26.9, 37.2, 24, 37.2)
    ..cubicTo(18.3, 37.2, 13.5, 33.4, 11.8, 28.2)
    ..lineTo(4.5, 28.2)
    ..lineTo(4.5, 33.9)
    ..cubicTo(8.1, 41.1, 15.5, 46, 24, 46)
    ..close();
  static final _yellow = Path()
    ..moveTo(11.8, 28.2)
    ..cubicTo(11.4, 26.9, 11.1, 25.5, 11.1, 24)
    ..cubicTo(11.1, 22.5, 11.4, 21.1, 11.8, 19.8)
    ..lineTo(11.8, 14.1)
    ..lineTo(4.5, 14.1)
    ..cubicTo(3, 17.1, 2, 20.4, 2, 24)
    ..cubicTo(2, 27.6, 3, 30.9, 4.5, 33.9)
    ..lineTo(11.8, 28.2)
    ..close();
  static final _red = Path()
    ..moveTo(24, 10.8)
    ..cubicTo(27.2, 10.8, 30.1, 11.9, 32.4, 14.1)
    ..lineTo(38.7, 7.8)
    ..cubicTo(34.9, 4.2, 29.9, 2, 24, 2)
    ..cubicTo(15.5, 2, 8.1, 6.9, 4.5, 14.1)
    ..lineTo(11.8, 19.8)
    ..cubicTo(13.5, 14.6, 18.3, 10.8, 24, 10.8)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.shortestSide / 48;
    canvas
      ..save()
      ..translate((size.width - 48 * k) / 2, (size.height - 48 * k) / 2)
      ..scale(k)
      ..drawPath(_blue, Paint()..color = const Color(0xFF4285F4))
      ..drawPath(_green, Paint()..color = const Color(0xFF34A853))
      ..drawPath(_yellow, Paint()..color = const Color(0xFFFBBC05))
      ..drawPath(_red, Paint()..color = const Color(0xFFEA4335))
      ..restore();
  }

  @override
  bool shouldRepaint(_GoogleMark oldDelegate) => false;
}

/// Apple logo (path from the sign-in board, 17×20 grid) in [color].
class _AppleMark extends CustomPainter {
  const _AppleMark(this.color);

  final Color color;

  static final _logo = Path()
    ..moveTo(14.1, 10.6)
    ..cubicTo(14.1, 8, 16.2, 6.8, 16.3, 6.7)
    ..cubicTo(15.1, 4.9, 13.2, 4.7, 12.6, 4.7)
    ..cubicTo(11, 4.5, 9.5, 5.6, 8.7, 5.6)
    ..cubicTo(7.9, 5.6, 6.7, 4.7, 5.3, 4.7)
    ..cubicTo(3.6, 4.8, 2, 5.8, 1.1, 7.4)
    ..cubicTo(-0.8, 10.6, 0.6, 15.4, 2.4, 18)
    ..cubicTo(3.3, 19.3, 4.3, 20.7, 5.7, 20.6)
    ..cubicTo(7, 20.5, 7.5, 19.7, 9.1, 19.7)
    ..cubicTo(10.7, 19.7, 11.1, 20.6, 12.5, 20.5)
    ..cubicTo(13.9, 20.5, 14.8, 19.2, 15.7, 17.9)
    ..cubicTo(16.7, 16.4, 17.1, 15, 17.1, 14.9)
    ..cubicTo(17.1, 14.9, 14.2, 13.8, 14.1, 10.6)
    ..close()
    ..moveTo(11.5, 3)
    ..cubicTo(12.2, 2.1, 12.7, 1, 12.6, -0.2)
    ..cubicTo(11.6, -0.2, 10.3, 0.5, 9.6, 1.4)
    ..cubicTo(8.9, 2.2, 8.4, 3.4, 8.5, 4.5)
    ..cubicTo(9.6, 4.6, 10.8, 3.9, 11.5, 3)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 17 < size.height / 20
        ? size.width / 17
        : size.height / 20;
    canvas
      ..save()
      ..translate((size.width - 17 * k) / 2, (size.height - 20 * k) / 2)
      ..scale(k)
      ..drawPath(_logo, Paint()..color = color)
      ..restore();
  }

  @override
  bool shouldRepaint(_AppleMark oldDelegate) => oldDelegate.color != color;
}
