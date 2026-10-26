import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';

/// Form field that opens a choice (currency, day): label above the value,
/// optional 32 icon tile in front, chevron at the end. 60 high; [compact] is
/// 56 high with a 15/500 value (CatDelete target picker).
class PickerField extends StatelessWidget {
  const PickerField({
    required this.label,
    required this.value,
    required this.onTap,
    this.placeholder = false,
    this.leading,
    this.compact = false,
    this.chevronSize,
    super.key,
  });

  /// Shown above the value; empty when the context already says it (the
  /// value alone is then read).
  final String label;
  final String value;

  /// [value] is a prompt ("Chọn ngày"), shown muted.
  final bool placeholder;
  final Widget? leading;
  final VoidCallback onTap;

  /// 56 high, padding 0 12 0 10, value 15/500.
  final bool compact;

  /// Chevron size; defaults to 16 next to a [leading] tile, 18 otherwise
  /// (and 18 when [compact]).
  final double? chevronSize;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(FreevaComponent.inputRadius);
    return Semantics(
      container: true,
      button: true,
      label: label.isEmpty ? value : '$label, $value',
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
            constraints: BoxConstraints(minHeight: compact ? 56 : 60),
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                leading == null ? 14 : 10,
                compact ? 0 : FreevaSpace.s2,
                compact ? FreevaSpace.s3 : 14,
                compact ? 0 : FreevaSpace.s2,
              ),
              child: Row(
                children: [
                  if (leading != null) ...[leading!, const SizedBox(width: 10)],
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (label.isNotEmpty) ...[
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
                        ],
                        Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: FreevaTypography.body.copyWith(
                            fontSize: compact ? 15 : 16,
                            fontWeight: compact ? FontWeight.w500 : null,
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
                    size:
                        chevronSize ??
                        (leading != null && !compact
                            ? FreevaSize.iconChip
                            : FreevaSize.iconSm),
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
      borderRadius: BorderRadius.circular(FreevaRadius.xs),
    ),
    child: Icon(icon, size: FreevaSize.iconChip, color: foreground),
  );
}
