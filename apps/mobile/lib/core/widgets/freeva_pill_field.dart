import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';

/// Pill input with a leading icon. Account screens only (sign in, sign up);
/// data forms use [FreevaTextField]. The label is for screen readers.
/// 54 high: icon 20 inset 18, text 16 from 48, eye toggle in a 44 box 6 from
/// the right. Focus: 1.5 `action.primary` border and a 4 px focus ring.
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
    final focused = _RingBorder(
      side: BorderSide(color: c.inputBorderFocus, width: FreevaBorder.selected),
      ring: c.focusRing.withValues(alpha: .18),
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
        style: FreevaTypography.body.copyWith(
          fontSize: 16,
          height: 1.2,
          color: c.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: widget.hint ?? widget.label,
          errorText: widget.error,
          errorMaxLines: 3,
          constraints: const BoxConstraints(minHeight: 54),
          contentPadding: EdgeInsets.fromLTRB(
            0,
            17,
            widget.obscure ? 0 : 18,
            17,
          ),
          hintStyle: FreevaTypography.body.copyWith(
            fontSize: 16,
            height: 1.2,
            color: c.textSecondary,
          ),
          prefixIconConstraints: const BoxConstraints.tightFor(width: 48),
          prefixIcon: Padding(
            padding: const EdgeInsetsDirectional.only(start: 18, end: 10),
            child: Icon(
              widget.icon,
              size: FreevaSize.iconInline,
              color: c.textSecondary,
            ),
          ),
          suffixIconConstraints: const BoxConstraints.tightFor(width: 50),
          suffixIcon: widget.obscure
              ? Padding(
                  padding: const EdgeInsetsDirectional.only(end: 6),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: FreevaSize.touch,
                      height: FreevaSize.touch,
                    ),
                    tooltip: _hidden ? s.passwordShow : s.passwordHide,
                    onPressed: () => setState(() => _hidden = !_hidden),
                    icon: Icon(
                      _hidden ? LucideIcons.eye : LucideIcons.eyeOff,
                      size: FreevaSize.iconInline,
                      color: c.textSecondary,
                    ),
                  ),
                )
              : null,
          border: border(c.inputBorder, FreevaBorder.defaultValue),
          enabledBorder: border(c.inputBorder, FreevaBorder.defaultValue),
          focusedBorder: focused,
          errorBorder: border(c.inputBorderError, FreevaBorder.defaultValue),
          focusedErrorBorder: border(c.inputBorderError, FreevaBorder.selected),
        ),
      ),
    );
  }
}

/// Pill outline that also paints the 4 px focus ring outside the stroke.
class _RingBorder extends OutlineInputBorder {
  const _RingBorder({required BorderSide side, required this.ring})
    : super(
        borderRadius: const BorderRadius.all(
          Radius.circular(FreevaRadius.full),
        ),
        borderSide: side,
      );

  final Color ring;

  @override
  _RingBorder copyWith({
    BorderSide? borderSide,
    BorderRadius? borderRadius,
    double? gapPadding,
  }) => _RingBorder(side: borderSide ?? this.borderSide, ring: ring);

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is OutlineInputBorder) {
      return _RingBorder(
        side: BorderSide.lerp(a.borderSide, borderSide, t),
        ring: ring.withValues(alpha: ring.a * t),
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is OutlineInputBorder) {
      return _RingBorder(
        side: BorderSide.lerp(borderSide, b.borderSide, t),
        ring: ring.withValues(alpha: ring.a * (1 - t)),
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) {
    final outer = rect.inflate(FreevaBorder.focusRing);
    canvas.drawDRRect(
      RRect.fromRectAndRadius(outer, Radius.circular(outer.height / 2)),
      RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2)),
      Paint()..color = ring,
    );
    super.paint(
      canvas,
      rect,
      gapStart: gapStart,
      gapExtent: gapExtent,
      gapPercentage: gapPercentage,
      textDirection: textDirection,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is _RingBorder && other.ring == ring && super == other;

  @override
  int get hashCode => Object.hash(super.hashCode, ring);
}
