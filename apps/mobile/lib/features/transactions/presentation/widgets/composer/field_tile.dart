import 'package:flutter/material.dart';

import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.g.dart';
import '../../../../../core/widgets/press_scale.dart';

/// White tile with a small icon square, a label and a value ("Ví · Tiền
/// mặt", "Ngày · Hôm nay"). Opens a picker sheet.
class FieldTile extends StatelessWidget {
  const FieldTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.iconBg,
    this.iconFg,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final Color? iconBg;
  final Color? iconFg;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: '$label, $value',
      excludeSemantics: true,
      child: PressScale(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.bgSurface,
            borderRadius: BorderRadius.circular(FreevaRadius.md),
            boxShadow: FreevaElevation.s1,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(FreevaRadius.md),
              onTap: onTap,
              child: Container(
                height: FreevaSize.button,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: iconBg ?? c.bgSubtle,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        size: FreevaSize.iconChip,
                        color: iconFg ?? c.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: FreevaTypography.overline.copyWith(
                              letterSpacing: 0,
                              fontWeight: FontWeight.w400,
                              color: c.textSecondary,
                            ),
                          ),
                          Text(
                            value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: FreevaTypography.bodyS.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: c.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
