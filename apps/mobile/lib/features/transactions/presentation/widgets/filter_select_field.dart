import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';

/// Select field that opens a sheet: label in the box, current value, chevron.
class FilterSelectField extends StatelessWidget {
  const FilterSelectField({
    required this.label,
    required this.value,
    required this.onTap,
    super.key,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(FreevaComponent.inputRadius);
    return Semantics(
      button: true,
      label: '$label, $value',
      excludeSemantics: true,
      child: Material(
        color: c.inputBg,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: c.inputBorder),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: FreevaSize.row),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: FreevaTypography.label.copyWith(
                          fontWeight: FontWeight.w400,
                          height: 1.25,
                          color: c.textSecondary,
                        ),
                      ),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: FreevaTypography.body.copyWith(
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                          color: c.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: FreevaSpace.s3),
                Icon(
                  LucideIcons.chevronRight,
                  size: FreevaSize.iconSm,
                  color: c.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
