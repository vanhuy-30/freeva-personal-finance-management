import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../viewmodels/auth_view_model.dart';
import 'auth_message.dart';
import 'auth_scaffold.dart';

/// Xác nhận email, first screen after sign-up. Optional: "Xong" moves on
/// whether or not the link was opened, and the account works either way.
class VerifyEmailStep extends StatelessWidget {
  const VerifyEmailStep({required this.model, required this.onDone, super.key});

  final AuthViewModel model;
  final VoidCallback onDone;

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
      topGap: FreevaSpace.s2,
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
                  style: FreevaTypography.bodyS.copyWith(
                    fontSize: 14,
                    color: c.textSecondary,
                  ),
                ),
              ),
              TextButton(
                onPressed: model.loading ? null : () => _resend(context),
                child: Text(s.authResendLink),
              ),
            ],
          ),
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
        Center(
          child: Container(
            width: 120,
            height: 84,
            decoration: BoxDecoration(
              color: c.bgSurface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: FreevaElevation.s2,
            ),
            child: Icon(LucideIcons.mail, size: 40, color: c.actionPrimary),
          ),
        ),
        const SizedBox(height: FreevaSpace.s5),
        AuthTitle(s.authVerifyTitle),
        const SizedBox(height: FreevaSpace.s2),
        Text.rich(
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
        const SizedBox(height: FreevaSpace.s5),
        FreevaCard(
          padding: const EdgeInsets.symmetric(
            horizontal: FreevaSpace.s4,
            vertical: FreevaSpace.s2,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 2),
                child: Text(
                  s.authVerifyWhyTitle,
                  style: FreevaTypography.label.copyWith(
                    color: c.textSecondary,
                  ),
                ),
              ),
              _Why(LucideIcons.keyRound, s.authVerifyWhyReset),
              _Why(LucideIcons.shieldAlert, s.authVerifyWhyAlert),
              _Why(LucideIcons.bell, s.authVerifyWhyNotice),
            ],
          ),
        ),
      ],
    );
  }
}

class _Why extends StatelessWidget {
  const _Why(this.icon, this.text);

  final IconData icon;
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
            child: Icon(icon, size: 17, color: c.tintBlueFg),
          ),
          const SizedBox(width: FreevaSpace.s3),
          Expanded(child: Text(text, style: FreevaTypography.body)),
        ],
      ),
    );
  }
}
