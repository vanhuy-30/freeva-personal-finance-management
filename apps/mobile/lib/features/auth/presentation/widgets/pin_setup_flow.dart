import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/pin_pad.dart';
import '../viewmodels/auth_view_model.dart';
import 'auth_message.dart';
import 'auth_scaffold.dart';

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
    final skip = TextButton(
      onPressed: model.loading ? null : widget.onSkip,
      child: Text(
        s.authLaterLink,
        style: FreevaTypography.titleM.copyWith(
          fontSize: 15,
          color: c.textSecondary,
        ),
      ),
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
      children: [
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: c.tintBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.lockKeyhole, size: 32, color: c.tintBlueFg),
          ),
        ),
        const SizedBox(height: FreevaSpace.s5),
        AuthTitle(
          confirm ? s.authPinConfirmTitle : s.authPinSetupTitle,
          subtitle: confirm ? s.authPinConfirmSub : s.authPinSetupSub,
        ),
        const SizedBox(height: 28),
        Center(
          child: PinDots(length: _typed.length, error: _mismatch),
        ),
        const SizedBox(height: FreevaSpace.s3),
        Semantics(
          liveRegion: true,
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
        AuthMessage(model: model),
        const Spacer(),
        PinKeypad(onDigit: _digit, onDelete: _delete),
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
      topGap: 48,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthMessage(model: model),
          const SizedBox(height: FreevaSpace.s2),
          FreevaButton(
            label: face ? s.authBiometricTitleFace : s.authBiometricSetup,
            size: FreevaButtonSize.l,
            expand: true,
            loading: model.loading,
            onPressed: onSetup,
          ),
          const SizedBox(height: FreevaSpace.s1),
          FreevaButton(
            label: s.authLaterLink,
            variant: FreevaButtonVariant.text,
            expand: true,
            onPressed: model.loading ? null : onSkip,
          ),
        ],
      ),
      children: [
        Center(
          child: Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              color: c.bgSurface,
              borderRadius: BorderRadius.circular(40),
              boxShadow: FreevaElevation.s2,
            ),
            child: Icon(
              face ? LucideIcons.scanFace : LucideIcons.fingerprint,
              size: 56,
              color: c.actionPrimary,
            ),
          ),
        ),
        const SizedBox(height: FreevaSpace.s8),
        AuthTitle(
          face ? s.authBiometricTitleFace : s.authBiometricTitle,
          subtitle: face ? s.authBiometricSubFace : s.authBiometricSub,
        ),
      ],
    );
  }
}
