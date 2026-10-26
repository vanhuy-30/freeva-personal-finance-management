import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/check_mark.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../viewmodels/auth_view_model.dart';
import 'auth_message.dart';
import 'auth_scaffold.dart';
import 'key_glyph.dart';

/// Xác nhận email, first screen after sign-up. Optional: "Xong" moves on
/// whether or not the link was opened, and the account works either way.
class VerifyEmailStep extends StatelessWidget {
  const VerifyEmailStep({
    required this.model,
    required this.onDone,
    this.onBack,
    super.key,
  });

  final AuthViewModel model;
  final VoidCallback onDone;

  /// Back to "Tạo tài khoản" (for a mistyped email).
  final VoidCallback? onBack;

  Future<void> _resend(BuildContext context) async {
    final message = S.of(context).authVerificationSent;
    await model.resendVerification();
    if (context.mounted && model.failure == null) {
      showFreevaToast(context, message: message, aboveNav: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    // The email is bold inside the sentence; split around a marker.
    final parts = s.authVerifySent('\u0001').split('\u0001');
    final body = FreevaTypography.body.copyWith(color: c.textSecondary);
    return AuthScaffold(
      onBack: model.loading ? null : onBack,
      topGap: 0,
      bottomInset: 32,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthMessage(model: model),
          FreevaButton(
            label: s.authDone,
            size: FreevaButtonSize.l,
            expand: true,
            onPressed: onDone,
          ),
          const SizedBox(height: FreevaSpace.s1),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  s.authResendPrompt,
                  textAlign: TextAlign.end,
                  style: FreevaTypography.bodyM.copyWith(
                    color: c.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: FreevaSpace.s1),
              TextButton(
                onPressed: model.loading ? null : () => _resend(context),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(FreevaSize.touch, FreevaSize.touch),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  s.authResendLink,
                  style: FreevaTypography.bodyM.copyWith(
                    fontWeight: FontWeight.w600,
                    color: c.textLink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: FreevaSpace.s1),
          Text(
            s.authVerifyLater,
            textAlign: TextAlign.center,
            style: FreevaTypography.bodyS.copyWith(
              fontSize: 13,
              height: 18 / 13,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
      children: [
        const _EnvelopeIllustration(),
        const SizedBox(height: FreevaSpace.s1),
        AuthTitle(s.authVerifyTitle),
        const SizedBox(height: FreevaSpace.s2),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text.rich(
              TextSpan(
                style: body,
                children: [
                  TextSpan(text: parts.first),
                  TextSpan(
                    text: model.email,
                    style: body.copyWith(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(text: parts.last),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: FreevaSpace.s5),
        FreevaCard(
          list: true,
          padding: const EdgeInsets.symmetric(
            horizontal: FreevaSpace.s4,
            vertical: 6,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 2),
                child: Text(
                  s.authVerifyWhyTitle,
                  style: FreevaTypography.bodyS.copyWith(
                    fontWeight: FontWeight.w600,
                    color: c.textSecondary,
                  ),
                ),
              ),
              _Why(null, s.authVerifyWhyReset),
              Divider(height: 1, thickness: 1, color: c.borderDivider),
              _Why(LucideIcons.shieldAlert, s.authVerifyWhyAlert),
              Divider(height: 1, thickness: 1, color: c.borderDivider),
              _Why(LucideIcons.bell, s.authVerifyWhyNotice),
            ],
          ),
        ),
      ],
    );
  }
}

/// Envelope on a soft halo with a check badge: 150 high, full bleed.
class _EnvelopeIllustration extends StatelessWidget {
  const _EnvelopeIllustration();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ExcludeSemantics(
      child: SizedBox(
        height: 150,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [c.tintBlue, c.bgSubtle, c.bgSubtle.withAlpha(0)],
                  stops: const [0, .55, .72],
                ),
              ),
            ),
            Positioned(
              top: 32,
              child: Transform.rotate(
                angle: -6 * math.pi / 180,
                child: Container(
                  width: 120,
                  height: 84,
                  decoration: BoxDecoration(
                    color: c.bgSurface,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        offset: Offset(0, 14),
                        blurRadius: 32,
                        color: Color(0x1F22283A),
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    painter: _EnvelopePainter(flap: c.data1, fold: c.data4),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 20,
              child: Transform.translate(
                offset: const Offset(40 + 17, 0),
                child: Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.actionPrimary,
                    border: Border.all(color: c.bgCanvas, width: 4),
                  ),
                  child: CheckMark(
                    color: c.textOnAction,
                    size: 14,
                    strokeWidth: 3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Envelope lines from the board (170 × 120 viewBox scaled to 120 × 84).
class _EnvelopePainter extends CustomPainter {
  const _EnvelopePainter({required this.flap, required this.fold});

  final Color flap;
  final Color fold;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 170;
    Offset p(double x, double y) => Offset(x * k, y * k);
    final flapPaint = Paint()
      ..color = flap
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5 * k
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final foldPaint = Paint()
      ..color = fold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * k
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawPath(
        Path()
          ..moveTo(p(8, 14).dx, p(8, 14).dy)
          ..lineTo(p(85, 70).dx, p(85, 70).dy)
          ..lineTo(p(162, 14).dx, p(162, 14).dy),
        flapPaint,
      )
      ..drawLine(p(8, 110), p(64, 56), foldPaint)
      ..drawLine(p(162, 110), p(106, 56), foldPaint);
  }

  @override
  bool shouldRepaint(_EnvelopePainter old) =>
      old.flap != flap || old.fold != fold;
}

class _Why extends StatelessWidget {
  const _Why(this.icon, this.text);

  /// Null draws the board's key glyph.
  final IconData? icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c.tintBlue,
              borderRadius: BorderRadius.circular(FreevaRadius.sm),
            ),
            alignment: Alignment.center,
            child: icon == null
                ? KeyGlyph(color: c.tintBlueFg, size: 17)
                : Icon(icon, size: 17, color: c.tintBlueFg),
          ),
          const SizedBox(width: FreevaSpace.s3),
          Expanded(
            child: Text(
              text,
              style: FreevaTypography.body.copyWith(
                height: 20 / 15,
                color: c.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
