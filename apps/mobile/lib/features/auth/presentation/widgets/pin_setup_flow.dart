import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/pin_pad.dart';
import '../viewmodels/auth_view_model.dart';
import 'auth_message.dart';
import 'auth_scaffold.dart';
import '../../../onboarding/presentation/widgets/onboarding_frame.dart';

enum _PinStep { enter, confirm, biometric }

/// Đặt mã PIN → Nhập lại mã PIN → Face ID (only when the device has it).
/// Every step can be left with "Để sau" ([onSkip]). Two PINs that differ
/// start again from the first one. [onDone] runs once the PIN is stored.
class PinSetupFlow extends StatefulWidget {
  const PinSetupFlow({
    required this.model,
    required this.onSkip,
    this.onBack,
    this.onDone,
    super.key,
  });

  final AuthViewModel model;
  final VoidCallback onSkip;
  final VoidCallback? onBack;
  final VoidCallback? onDone;

  @override
  State<PinSetupFlow> createState() => _PinSetupFlowState();
}

class _PinSetupFlowState extends State<PinSetupFlow> {
  var _step = _PinStep.enter;
  var _pin = '';
  var _repeat = '';
  var _mismatch = false;

  String get _typed => _step == _PinStep.enter ? _pin : _repeat;

  void _digit(String d) {
    if (widget.model.loading || _typed.length >= PinDots.total) return;
    setState(() {
      if (_step == _PinStep.enter) {
        _pin += d;
      } else {
        _repeat += d;
      }
      _mismatch = false;
    });
  }

  void _delete() {
    if (widget.model.loading || _typed.isEmpty) return;
    setState(() {
      if (_step == _PinStep.enter) {
        _pin = _pin.substring(0, _pin.length - 1);
      } else {
        _repeat = _repeat.substring(0, _repeat.length - 1);
      }
    });
  }

  void _back() {
    if (_step == _PinStep.confirm) {
      setState(() {
        _step = _PinStep.enter;
        _pin = '';
        _repeat = '';
      });
    } else {
      widget.onBack?.call();
    }
  }

  Future<void> _next() async {
    switch (_step) {
      case _PinStep.enter:
        setState(() => _step = _PinStep.confirm);
      case _PinStep.confirm:
        if (_pin != _repeat) {
          setState(() {
            _step = _PinStep.enter;
            _pin = '';
            _repeat = '';
            _mismatch = true;
          });
        } else if (widget.model.biometricAvailable) {
          setState(() => _step = _PinStep.biometric);
        } else {
          await _finish(biometric: false);
        }
      case _PinStep.biometric:
        await _finish(biometric: true);
    }
  }

  Future<void> _finish({required bool biometric}) async {
    final reason = S.of(context).authBiometricReason;
    await widget.model.setupPin(_pin, _pin, biometric, reason);
    if (!mounted) return;
    if (widget.model.failure == null) {
      widget.onDone?.call();
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    final s = S.of(context);
    final c = context.colors;
    final skip = OnboardingSkipLink(
      label: s.authLaterLink,
      onPressed: model.loading ? null : widget.onSkip,
    );
    if (_step == _PinStep.biometric) {
      return _BiometricStep(
        model: model,
        onSetup: _next,
        onSkip: () => _finish(biometric: false),
      );
    }
    final confirm = _step == _PinStep.confirm;
    return AuthScaffold(
      onBack: _step == _PinStep.confirm || widget.onBack != null ? _back : null,
      trailing: skip,
      topGap: FreevaSpace.s3,
      narrow: true,
      bottomInset: 32,
      children: [
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: c.tintBlue,
              shape: BoxShape.circle,
            ),
            child: CustomPaint(
              painter: _PadlockPainter(c.tintBlueFg, check: confirm),
            ),
          ),
        ),
        const SizedBox(height: FreevaSpace.s5),
        AuthTitle(
          confirm ? s.authPinConfirmTitle : s.authPinSetupTitle,
          subtitle: confirm ? s.authPinConfirmSub : s.authPinSetupSub,
          style: FreevaTypography.titleXl.copyWith(
            fontSize: 26,
            height: 32 / 26,
            letterSpacing: -0.5,
          ),
          subtitleMaxWidth: 290,
        ),
        const SizedBox(height: 28),
        Center(
          child: PinDots(length: _typed.length, error: _mismatch),
        ),
        const SizedBox(height: 14),
        Semantics(
          liveRegion: true,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 20),
            child: Text(
              _mismatch
                  ? s.authPinMismatch
                  : (confirm ? s.authPinConfirmHint : ''),
              textAlign: TextAlign.center,
              style: FreevaTypography.bodyS.copyWith(
                color: _mismatch ? c.statusDanger : c.textSecondary,
              ),
            ),
          ),
        ),
        AuthMessage(model: model),
        const Spacer(),
        PinKeypad(onDigit: _digit, onDelete: _delete, keyHeight: 60, rowGap: 6),
        const SizedBox(height: FreevaSpace.s4),
        FreevaButton(
          label: confirm ? s.authConfirm : s.authContinue,
          size: FreevaButtonSize.l,
          expand: true,
          loading: model.loading,
          onPressed: _typed.length == PinDots.total ? _next : null,
        ),
      ],
    );
  }
}

class _BiometricStep extends StatelessWidget {
  const _BiometricStep({
    required this.model,
    required this.onSetup,
    required this.onSkip,
  });

  final AuthViewModel model;
  final VoidCallback onSetup;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final face = defaultTargetPlatform == TargetPlatform.iOS;
    return AuthScaffold(
      topGap: FreevaSpace.s6,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthMessage(model: model),
          FreevaButton(
            label: face ? s.authBiometricTitleFace : s.authBiometricSetup,
            size: FreevaButtonSize.l,
            expand: true,
            loading: model.loading,
            onPressed: onSetup,
          ),
          const SizedBox(height: FreevaSpace.s1),
          TextButton(
            onPressed: model.loading ? null : onSkip,
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: c.textSecondary,
            ),
            child: Text(
              s.authLaterLink,
              style: FreevaTypography.titleM.copyWith(color: c.textSecondary),
            ),
          ),
        ],
      ),
      children: [
        _BiometricIllustration(face: face),
        const SizedBox(height: FreevaSpace.s2),
        AuthTitle(
          face ? s.authBiometricTitleFace : s.authBiometricTitle,
          subtitle: face ? s.authBiometricSubFace : s.authBiometricSub,
          subtitleGap: FreevaSpace.s3,
          subtitleMaxWidth: 300,
        ),
      ],
    );
  }
}

/// Face ID tile on a halo with a dashed ring and three dots (380 high).
class _BiometricIllustration extends StatelessWidget {
  const _BiometricIllustration({required this.face});

  final bool face;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget dot(double size, Color color) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
    return ExcludeSemantics(
      child: SizedBox(
        height: 380,
        child: LayoutBuilder(
          builder: (context, box) {
            // Dot offsets are from the 390 frame edges; the content box is
            // 48 narrower, so shift them by the side margin.
            final inset = (390 - box.maxWidth) / 2;
            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  top: 20,
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          c.tintBlue,
                          c.bgSubtle,
                          c.bgSubtle.withAlpha(0),
                        ],
                        stops: const [0, .55, .72],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 70,
                  child: CustomPaint(
                    size: const Size.square(220),
                    painter: _DashedRingPainter(c.borderStrong),
                  ),
                ),
                Positioned(
                  top: 115,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      color: c.bgSurface,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          offset: const Offset(0, 16),
                          blurRadius: 40,
                          color: c.actionPrimary.withValues(alpha: .2),
                        ),
                      ],
                    ),
                    child: Icon(
                      face ? LucideIcons.scanFace : LucideIcons.fingerprint,
                      size: 64,
                      color: c.actionPrimary,
                    ),
                  ),
                ),
                Positioned(left: 62 - inset, top: 92, child: dot(12, c.data2)),
                Positioned(right: 70 - inset, top: 250, child: dot(9, c.data3)),
                Positioned(
                  right: 92 - inset,
                  top: 74,
                  child: dot(7, FreevaPrimitive.cyan300),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 1 px dashed circle.
class _DashedRingPainter extends CustomPainter {
  const _DashedRingPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final r = size.width / 2;
    const dash = 3.0;
    final count = (2 * math.pi * r / (dash * 2)).floor();
    final step = 2 * math.pi / count;
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: r);
    for (var i = 0; i < count; i++) {
      canvas.drawArc(rect, i * step, step / 2, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedRingPainter old) => old.color != color;
}

/// Padlock from the PIN boards (24 grid, stroke 1.5, 34 px), optionally with
/// a check inside the body (confirm step).
class _PadlockPainter extends CustomPainter {
  const _PadlockPainter(this.color, {required this.check});

  final Color color;
  final bool check;

  @override
  void paint(Canvas canvas, Size size) {
    const glyph = 34.0;
    const k = glyph / 24;
    canvas
      ..save()
      ..translate((size.width - glyph) / 2, (size.height - glyph) / 2)
      ..scale(k);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(5, 11, 14, 10),
          const Radius.circular(2),
        ),
        paint,
      )
      ..drawPath(
        Path()
          ..moveTo(8, 11)
          ..lineTo(8, 7)
          ..arcToPoint(const Offset(16, 7), radius: const Radius.circular(4))
          ..lineTo(16, 11),
        paint,
      );
    if (check) {
      canvas.drawPath(
        Path()
          ..moveTo(10, 16)
          ..lineTo(11.5, 17.5)
          ..lineTo(14, 15),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PadlockPainter old) =>
      old.color != color || old.check != check;
}
