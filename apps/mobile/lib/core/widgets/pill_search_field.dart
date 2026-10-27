import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';

/// Filled filter box for short lists (tags, FAQ): subtle grey, radius 16,
/// 48 high, 18 search icon, 16 text. Focus adds the 1.5 primary border.
class PillSearchField extends StatelessWidget {
  const PillSearchField({
    required this.hint,
    required this.onChanged,
    super.key,
  });

  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    OutlineInputBorder border([BorderSide side = BorderSide.none]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(FreevaRadius.md),
          borderSide: side,
        );
    final text = FreevaTypography.body.copyWith(fontSize: 16);
    return Semantics(
      textField: true,
      label: hint,
      child: TextField(
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: text.copyWith(color: c.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: text.copyWith(color: c.textSecondary),
          filled: true,
          fillColor: c.bgSubtle,
          prefixIcon: Padding(
            padding: const EdgeInsetsDirectional.only(start: 14, end: 10),
            child: Icon(
              LucideIcons.search,
              size: FreevaSize.iconSm,
              color: c.textSecondary,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minHeight: 48),
          constraints: const BoxConstraints(minHeight: 48),
          contentPadding: const EdgeInsetsDirectional.fromSTEB(0, 12, 14, 12),
          border: border(),
          enabledBorder: border(),
          focusedBorder: border(
            BorderSide(color: c.inputBorderFocus, width: FreevaBorder.selected),
          ),
        ),
      ),
    );
  }
}
