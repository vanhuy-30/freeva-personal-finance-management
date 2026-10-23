import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_text_field.dart';
import '../../../auth/domain/auth_repository.dart';

/// One hidden-input field of the PIN / password forms.
class SecretField extends StatelessWidget {
  const SecretField({
    required this.label,
    required this.controller,
    this.error,
    this.pin = false,
    this.onChanged,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final String? error;
  final bool pin;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) => FreevaTextField(
    label: label,
    controller: controller,
    error: error,
    obscureText: true,
    keyboardType: pin ? TextInputType.number : TextInputType.visiblePassword,
    inputFormatters: pin
        ? [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ]
        : null,
    onChanged: (_) => onChanged?.call(),
  );
}

/// Scrolling form body: a hint, fields with gaps and one full-width button.
class SecurityFormBody extends StatelessWidget {
  const SecurityFormBody({
    required this.fields,
    required this.label,
    required this.busy,
    required this.onSubmit,
    this.hint,
    super.key,
  });

  final List<Widget> fields;
  final String label;
  final bool busy;
  final VoidCallback? onSubmit;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final margin = context.screenMargin;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        margin,
        FreevaSpace.s2,
        margin,
        FreevaSpace.s8,
      ),
      children: [
        if (hint != null)
          Padding(
            padding: const EdgeInsets.only(bottom: FreevaSpace.s4),
            child: Text(
              hint!,
              style: FreevaTypography.bodyS.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ),
        for (final field in fields) ...[
          field,
          const SizedBox(height: FreevaSpace.s3),
        ],
        const SizedBox(height: FreevaSpace.s3),
        FreevaButton(
          label: label,
          expand: true,
          onPressed: busy ? null : onSubmit,
        ),
      ],
    );
  }
}

/// Message for a failed security action, written for the field it concerns.
String securityError(S s, AuthFailure failure, {required bool pin}) =>
    switch (failure.code) {
      AuthError.wrongPin => s.mePinWrong,
      AuthError.credentials => s.mePasswordWrong,
      AuthError.passwordMismatch =>
        pin ? s.mePinMismatch : s.mePasswordMismatch,
      AuthError.invalidInput ||
      AuthError.invalidToken => pin ? s.mePinInvalid : s.mePasswordWeak,
      AuthError.rateLimited => s.meBusyRetry(
        ((failure.retryAfter ?? 900) / 60).ceil(),
      ),
      AuthError.network => s.meNetworkError,
      _ => s.meSaveError,
    };
