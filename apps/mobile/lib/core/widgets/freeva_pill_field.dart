import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';

/// Pill input with a leading icon. Account screens only (sign in, sign up);
/// data forms use [FreevaTextField]. The label is for screen readers.
class FreevaPillField extends StatefulWidget {
  const FreevaPillField({
    required this.label,
    required this.icon,
    this.controller,
    this.hint,
    this.error,
    this.obscure = false,
    this.keyboardType,
    this.autofillHints,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    super.key,
  });

  final String label;
  final IconData icon;
  final TextEditingController? controller;
  final String? hint;
  final String? error;

  /// Password field: hides the text and shows an eye toggle.
  final bool obscure;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<FreevaPillField> createState() => _FreevaPillFieldState();
}

class _FreevaPillFieldState extends State<FreevaPillField> {
  late var _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = S.of(context);
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(FreevaRadius.full),
      borderSide: BorderSide(color: color, width: width),
    );
    return Semantics(
      label: widget.label,
      textField: true,
      child: TextField(
        controller: widget.controller,
        obscureText: _hidden,
        keyboardType: widget.keyboardType,
        autofillHints: widget.autofillHints,
        textInputAction: widget.textInputAction,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        style: FreevaTypography.body.copyWith(color: c.textPrimary),
        decoration: InputDecoration(
          hintText: widget.hint ?? widget.label,
          errorText: widget.error,
          errorMaxLines: 3,
          constraints: const BoxConstraints(minHeight: 54),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: FreevaSpace.s5,
            vertical: 17,
          ),
          prefixIcon: Icon(
            widget.icon,
            size: FreevaSize.iconInline,
            color: c.textSecondary,
          ),
          suffixIcon: widget.obscure
              ? IconButton(
                  tooltip: _hidden ? s.passwordShow : s.passwordHide,
                  onPressed: () => setState(() => _hidden = !_hidden),
                  icon: Icon(
                    _hidden ? LucideIcons.eye : LucideIcons.eyeOff,
                    size: FreevaSize.iconInline,
                    color: c.textSecondary,
                  ),
                )
              : null,
          border: border(c.inputBorder, FreevaBorder.defaultValue),
          enabledBorder: border(c.inputBorder, FreevaBorder.defaultValue),
          focusedBorder: border(c.inputBorderFocus, FreevaBorder.selected),
          errorBorder: border(c.inputBorderError, FreevaBorder.defaultValue),
          focusedErrorBorder: border(c.inputBorderError, FreevaBorder.selected),
        ),
      ),
    );
  }
}
