import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';

/// Pill-shaped filter box for short lists (tags, FAQ).
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
    OutlineInputBorder border([Color? color, double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(FreevaRadius.full),
          borderSide: BorderSide(color: color ?? c.inputBorder, width: width),
        );
    return Semantics(
      textField: true,
      label: hint,
      child: TextField(
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: FreevaTypography.body.copyWith(color: c.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(
            LucideIcons.search,
            size: FreevaSize.iconInline,
            color: c.textSecondary,
          ),
          constraints: const BoxConstraints(minHeight: 48),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: border(),
          enabledBorder: border(),
          focusedBorder: border(c.inputBorderFocus, FreevaBorder.selected),
        ),
      ),
    );
  }
}
