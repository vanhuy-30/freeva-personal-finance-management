import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';
import 'field_error_hint.dart';

/// Data-form field (boards `.fld`): label inside the box, always visible,
/// value 16, at least 60 high. Optional 32 [leadingIcon] tile and a
/// "n/max" counter. Error shows a border, an icon and a hint that says how to
/// fix it. `locked` greys the box and shows `lockedReason` instead of an
/// editable value.
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
    this.suffix,
    this.obscureText = false,
    this.leadingIcon,
    this.maxLength,
    this.showCounter = false,
    super.key,
  }) : assert(!showCounter || (controller != null && maxLength != null));

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

  /// Short unit after the value, such as "₫".
  final String? suffix;

  /// Passwords and PINs: dots instead of characters, no suggestions.
  final bool obscureText;

  /// Glyph in a 32 subtle tile (radius 10) in front of the label and value.
  final IconData? leadingIcon;

  /// Hard limit on the number of characters.
  final int? maxLength;

  /// Shows "n/[maxLength]" at the bottom right (12, textDisabled). Needs a
  /// [controller] and [maxLength].
  final bool showCounter;

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
    final labelColor = error != null ? c.statusDanger : c.textSecondary;
    final valueStyle = FreevaTypography.body.copyWith(
      fontSize: 16,
      color: widget.locked ? c.textSecondary : c.textPrimary,
      fontFeatures: widget.tabular
          ? const [FontFeature.tabularFigures()]
          : null,
    );
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: FreevaTypography.label.copyWith(
            fontWeight: FontWeight.w400,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                enabled: !widget.locked,
                keyboardType: widget.keyboardType,
                inputFormatters: widget.inputFormatters,
                textInputAction: widget.textInputAction,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                maxLines: widget.obscureText ? 1 : widget.maxLines,
                maxLength: widget.maxLength,
                obscureText: widget.obscureText,
                enableSuggestions: !widget.obscureText,
                autocorrect: !widget.obscureText,
                style: valueStyle,
                // The box above draws border and fill; the theme's
                // outlined input style must not apply here.
                decoration: InputDecoration(
                  isCollapsed: true,
                  counterText: '',
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
            ),
            if (widget.suffix != null)
              Padding(
                padding: const EdgeInsets.only(left: FreevaSpace.s1),
                child: ExcludeSemantics(
                  child: Text(
                    widget.suffix!,
                    style: FreevaTypography.body.copyWith(
                      fontSize: 14,
                      color: c.textSecondary,
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (widget.showCounter && widget.maxLength != null)
          Padding(
            padding: const EdgeInsets.only(top: FreevaSpace.s1),
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: _Counter(
                controller: widget.controller!,
                max: widget.maxLength!,
              ),
            ),
          ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: FreevaMotion.fast,
          constraints: const BoxConstraints(minHeight: 60),
          padding: EdgeInsetsDirectional.fromSTEB(
            widget.leadingIcon == null ? 14 : 10,
            FreevaSpace.s2,
            14,
            FreevaSpace.s2,
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
          child: Row(
            children: [
              if (widget.leadingIcon != null) ...[
                ExcludeSemantics(
                  child: Container(
                    width: FreevaSize.iconTile,
                    height: FreevaSize.iconTile,
                    decoration: BoxDecoration(
                      color: c.bgSubtle,
                      borderRadius: BorderRadius.circular(FreevaRadius.xs),
                    ),
                    child: Icon(
                      widget.leadingIcon,
                      size: FreevaSize.iconChip,
                      color: c.textOnWash,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(child: body),
            ],
          ),
        ),
        if (error != null) FieldErrorHint(error),
      ],
    );
  }
}

/// "n/max" under a field's value; follows the controller.
class _Counter extends StatelessWidget {
  const _Counter({required this.controller, required this.max});

  final TextEditingController controller;
  final int max;

  @override
  Widget build(BuildContext context) {
    final style = FreevaTypography.label.copyWith(
      fontWeight: FontWeight.w400,
      color: context.colors.textDisabled,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) =>
          Text('${value.text.characters.length}/$max', style: style),
    );
  }
}
