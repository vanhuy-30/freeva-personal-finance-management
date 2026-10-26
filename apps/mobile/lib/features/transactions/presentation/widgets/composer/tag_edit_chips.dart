import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.g.dart';

/// Editable tag chips (violet, 36 high, ×) and "+ Thêm nhãn".
class TagEditChips extends StatelessWidget {
  const TagEditChips({
    required this.names,
    required this.ids,
    required this.onRemove,
    required this.onAdd,
    super.key,
  });

  final Map<String, String> names;
  final List<String> ids;
  final ValueChanged<String> onRemove;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    Widget chip({
      required Widget child,
      required VoidCallback onTap,
      required String label,
      Color? bg,
      Color? border,
    }) => Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: bg ?? Colors.transparent,
        shape: StadiumBorder(
          side: border == null ? BorderSide.none : BorderSide(color: border),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: SizedBox(
            height: 36,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(widthFactor: 1, child: child),
            ),
          ),
        ),
      ),
    );
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final id in ids)
          chip(
            label: s.txChipRemove(names[id] ?? ''),
            bg: c.tintViolet,
            onTap: () => onRemove(id),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  names[id] ?? '',
                  style: FreevaTypography.bodyS.copyWith(
                    fontWeight: FontWeight.w600,
                    color: c.tintVioletFg,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(LucideIcons.x, size: 14, color: c.tintVioletFg),
              ],
            ),
          ),
        chip(
          label: s.txAddTag,
          border: c.borderDefault,
          onTap: onAdd,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.plus, size: 14, color: c.textLink),
              const SizedBox(width: 4),
              Text(
                s.txAddTag,
                style: FreevaTypography.bodyS.copyWith(
                  fontWeight: FontWeight.w600,
                  color: c.textLink,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
