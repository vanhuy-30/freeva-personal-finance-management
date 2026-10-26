import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_dialog.dart';
import '../../../../core/widgets/pin_pad.dart';
import '../viewmodels/auth_view_model.dart';
import '../../domain/auth_repository.dart';
import '../widgets/auth_message.dart';
import '../../../settings/presentation/widgets/avatar_letter.dart';

/// Daily unlock: the PIN keypad, with Face ID / fingerprint in the corner when
/// it is on, and "Quên mã PIN?" to sign in again.
class LockPage extends StatefulWidget {
  const LockPage({required this.model, super.key});

  final AuthViewModel model;

  @override
  State<LockPage> createState() => _LockPageState();
}

class _LockPageState extends State<LockPage> {
  var _pin = '';

  Future<void> _digit(String d) async {
    final model = widget.model;
    if (model.loading || _pin.length >= PinDots.total) return;
    setState(() => _pin += d);
    if (_pin.length < PinDots.total) return;
    final entered = _pin;
    await model.unlockPin(entered);
    if (mounted) setState(() => _pin = '');
  }

  void _delete() {
    if (widget.model.loading || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _forgot() async {
    final s = S.of(context);
    final model = widget.model;
    final confirmed = await showFreevaConfirm(
      context: context,
      title: s.authForgotPin,
      message: s.authForgotPinMessage,
      cancelLabel: s.authCancel,
      confirmLabel: s.authForgotPinConfirm,
    );
    if (confirmed) await model.forgetDevice();
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    final s = S.of(context);
    final c = context.colors;
    final face = Theme.of(context).platform == TargetPlatform.iOS;
    // Board: "Quên mã PIN?" sits 40 above the screen edge, home indicator
    // included; SafeArea covers the indicator.
    final bottom = (40 - MediaQuery.viewPaddingOf(context).bottom)
        .clamp(FreevaSpace.s2, 40)
        .toDouble();
    return Scaffold(
      backgroundColor: c.bgCanvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      FreevaSpace.s8,
                      FreevaSpace.s6,
                      FreevaSpace.s8,
                      bottom,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: FreevaSpace.s6),
                        if (model.name != null)
                          AvatarLetter(name: model.name, email: null, size: 72)
                        else
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: c.bgAvatar,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              LucideIcons.lock,
                              size: 28,
                              color: c.actionPrimary,
                            ),
                          ),
                        const SizedBox(height: FreevaSpace.s5),
                        Semantics(
                          header: true,
                          child: Text(
                            model.name == null
                                ? s.authLockWelcome
                                : s.authLockGreeting(model.name!),
                            textAlign: TextAlign.center,
                            style: FreevaTypography.headline.copyWith(
                              color: c.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          s.authLockTitle,
                          style: FreevaTypography.bodyS.copyWith(
                            fontSize: 14,
                            color: c.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 36),
                        PinDots(
                          length: _pin.length,
                          error: model.failure?.code == AuthError.wrongPin,
                        ),
                        AuthMessage(model: model),
                        const Spacer(),
                        const SizedBox(height: FreevaSpace.s4),
                        PinKeypad(
                          onDigit: _digit,
                          onDelete: _delete,
                          leading: model.biometricAvailable
                              ? PinKey(
                                  label: face
                                      ? s.authUseFaceId
                                      : s.authUseBiometric,
                                  icon: face
                                      ? LucideIcons.scanFace
                                      : LucideIcons.fingerprint,
                                  iconColor: c.actionPrimary,
                                  iconSize: 30,
                                  onTap: () => model.unlockBiometric(
                                    s.authBiometricReason,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: FreevaSpace.s6),
                        TextButton(
                          onPressed: model.loading ? null : _forgot,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.all(FreevaSpace.s3),
                          ),
                          child: Text(
                            s.authForgotPin,
                            style: FreevaTypography.bodyM.copyWith(
                              fontWeight: FontWeight.w600,
                              color: c.textLink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
