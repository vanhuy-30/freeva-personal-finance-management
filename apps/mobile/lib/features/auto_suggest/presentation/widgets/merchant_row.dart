import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../categories/presentation/widgets/category_badge.dart';
import '../../domain/merchant_mapping.dart';

/// One remembered merchant: 32 grey category tile, merchant name over the
/// category name, and a 36 × button that forgets it. [minHeight] 54.
class MerchantRow extends StatelessWidget {
  const MerchantRow({
    required this.mapping,
    required this.onForget,
    this.minHeight = 54,
    super.key,
  });

  final MerchantMapping mapping;
  final VoidCallback onForget;

  /// 53 for rows under a divider, so each row plus its line is 54.
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: FreevaSpace.s4,
          vertical: FreevaSpace.s2,
        ),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Container(
                width: FreevaSize.iconTile,
                height: FreevaSize.iconTile,
                decoration: BoxDecoration(
                  color: c.bgSubtle,
                  borderRadius: BorderRadius.circular(FreevaRadius.xs),
                ),
                child: Icon(
                  categoryIcon(mapping.iconToken),
                  size: 17,
                  color: c.textOnWash,
                ),
              ),
            ),
            const SizedBox(width: FreevaSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mapping.merchant,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FreevaTypography.body.copyWith(
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    mapping.categoryName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FreevaTypography.label.copyWith(
                      fontWeight: FontWeight.w400,
                      height: 1.2,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: FreevaSpace.s3),
            Semantics(
              button: true,
              label: s.autoSuggestForget(mapping.merchant),
              excludeSemantics: true,
              child: InkResponse(
                onTap: onForget,
                radius: 18,
                splashFactory: NoSplash.splashFactory,
                highlightColor: c.bgSubtle,
                child: SizedBox.square(
                  dimension: 36,
                  child: Icon(
                    LucideIcons.x,
                    size: FreevaSize.iconChip,
                    color: c.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
