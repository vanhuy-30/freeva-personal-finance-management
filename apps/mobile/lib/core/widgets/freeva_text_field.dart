import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';
import 'field_error_hint.dart';

/// Data-form field: label inside the box, always visible. Error shows a
/// border, an icon and a hint that says how to fix it. `locked` greys the box
/// and shows `lockedReason` instead of an editable value.
class FreevaTextField extends StatefulWidget {
  const FreevaTextField({
    required this.label,
    this.controller,
    this.hint,
    this.error,
    this.locked = false,
    this.keyboardType,
    this.inputFormatters,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.tabular = false,
    this.maxLines = 1,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? error;
  final bool locked;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool tabular;
  final int maxLines;

  @override
  State<FreevaTextField> createState() => _FreevaTextFieldState();
}

class _FreevaTextFieldState extends State<FreevaTextField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final error = widget.error;
    final focused = _focus.hasFocus;
    final borderColor = error != null
        ? c.inputBorderError
        : focused
        ? c.inputBorderFocus
        : widget.locked
        ? c.borderDivider
        : c.inputBorder;
    final labelColor = error != null
        ? c.statusDanger
        : focused
        ? c.textLink
        : c.textSecondary;
    final valueStyle = FreevaTypography.body.copyWith(
      color: widget.locked ? c.textSecondary : c.textPrimary,
      fontFeatures: widget.tabular
          ? const [FontFeature.tabularFigures()]
          : null,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: FreevaMotion.fast,
          padding: const EdgeInsets.symmetric(
            horizontal: FreevaSpace.s4,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: widget.locked ? c.bgSubtle : c.inputBg,
            borderRadius: BorderRadius.circular(FreevaComponent.inputRadius),
            border: Border.all(
              color: borderColor,
              width: focused || error != null
                  ? FreevaBorder.selected
                  : FreevaBorder.defaultValue,
            ),
            boxShadow: focused && error == null
                ? [
                    BoxShadow(
                      color: c.focusRing.withValues(alpha: .18),
                      spreadRadius: FreevaBorder.focusRing,
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.label,
                style: FreevaTypography.label.copyWith(color: labelColor),
              ),
              const SizedBox(height: 3),
              TextField(
                controller: widget.controller,
                focusNode: _focus,
                enabled: !widget.locked,
                keyboardType: widget.keyboardType,
                inputFormatters: widget.inputFormatters,
                textInputAction: widget.textInputAction,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                maxLines: widget.maxLines,
                style: valueStyle,
                // The box above draws border and fill; the theme's
                // outlined input style must not apply here.
                decoration: InputDecoration(
                  isCollapsed: true,
                  contentPadding: EdgeInsets.zero,
                  filled: false,
                  hintText: widget.hint,
                  hintStyle: valueStyle.copyWith(color: c.textSecondary),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                ),
              ),
            ],
          ),
        ),
        if (error != null) FieldErrorHint(error),
      ],
    );
  }
}
