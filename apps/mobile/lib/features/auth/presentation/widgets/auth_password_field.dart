import 'package:flutter/material.dart';
import '../../../../core/l10n/generated/app_localizations.dart';

class AuthPasswordField extends StatefulWidget {
  const AuthPasswordField(
      {required this.controller,
      required this.enabled,
      required this.label,
      required this.newPassword,
      this.helper,
      this.onSubmit,
      super.key});
  final TextEditingController controller;
  final bool enabled, newPassword;
  final String label;
  final String? helper;
  final VoidCallback? onSubmit;
  @override
  State<AuthPasswordField> createState() => _AuthPasswordFieldState();
}

class _AuthPasswordFieldState extends State<AuthPasswordField> {
  bool _obscured = true;
  @override
  Widget build(BuildContext context) => TextField(
        controller: widget.controller,
        enabled: widget.enabled,
        decoration: InputDecoration(
            labelText: widget.label,
            helperText: widget.helper,
            suffixIcon: IconButton(
                onPressed: widget.enabled
                    ? () => setState(() => _obscured = !_obscured)
                    : null,
                tooltip: _obscured
                    ? S.of(context).authShowPassword
                    : S.of(context).authHidePassword,
                icon: Icon(
                    _obscured
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20))),
        obscureText: _obscured,
        autocorrect: false,
        enableSuggestions: false,
        autofillHints: [
          widget.newPassword
              ? AutofillHints.newPassword
              : AutofillHints.password
        ],
        textInputAction:
            widget.onSubmit == null ? TextInputAction.next : TextInputAction.go,
        onSubmitted: widget.enabled && widget.onSubmit != null
            ? (_) => widget.onSubmit!()
            : null,
      );
}
