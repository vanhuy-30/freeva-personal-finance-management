import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.g.dart';

/// Form field that opens a choice (currency, day): label above the value,
/// optional 32 icon tile in front, chevron at the end. 60 high.
class PickerField extends StatelessWidget {
  const PickerField({
    required this.label,
    required this.value,
    required this.onTap,
    this.placeholder = false,
    this.leading,
    super.key,
  });

  final String label;
  final String value;

  /// [value] is a prompt ("Chọn ngày"), shown muted.
  final bool placeholder;
  final Widget? leading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(FreevaComponent.inputRadius);
    return Semantics(
      container: true,
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
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 60),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                leading == null ? FreevaSpace.s4 : 10,
                FreevaSpace.s2,
                FreevaSpace.s3,
                FreevaSpace.s2,
              ),
              child: Row(
                children: [
                  if (leading != null) ...[leading!, const SizedBox(width: 10)],
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: FreevaTypography.label.copyWith(
                            fontWeight: FontWeight.w400,
                            color: c.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: FreevaTypography.body.copyWith(
                            fontSize: 16,
                            color: placeholder
                                ? c.textSecondary
                                : c.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    LucideIcons.chevronDown,
                    size: 18,
                    color: c.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 32 icon tile in front of a [PickerField] (day fields).
class FieldIconTile extends StatelessWidget {
  const FieldIconTile({
    required this.icon,
    required this.background,
    required this.foreground,
    super.key,
  });

  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
    width: FreevaSize.iconTile,
    height: FreevaSize.iconTile,
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Icon(icon, size: 16, color: foreground),
  );
}
