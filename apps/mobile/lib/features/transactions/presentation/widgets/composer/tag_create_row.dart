import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.g.dart';

/// Quick-create row: primary text, `tint.blue` square with +.
class TagCreateRow extends StatelessWidget {
  const TagCreateRow({
    required this.label,
    required this.onTap,
    this.busy = false,
    super.key,
  });

  final String label;
  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: c.tintBlue,
                borderRadius: BorderRadius.circular(7),
              ),
              child: busy
                  ? Padding(
                      padding: const EdgeInsets.all(4),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: c.actionPrimary,
                      ),
                    )
                  : Icon(
                      LucideIcons.plus,
                      size: FreevaSize.iconXs,
                      color: c.actionPrimary,
                    ),
            ),
            const SizedBox(width: FreevaSpace.s3),
            Expanded(
              child: Text(
                label,
                style: FreevaTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: onTap == null ? c.textDisabled : c.textLink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
