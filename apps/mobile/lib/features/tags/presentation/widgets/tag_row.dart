import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../domain/tag.dart';

/// One tag: violet tile, name, how many transactions, chevron. Tapping it
/// opens the actions (Xem giao dịch, Đổi tên, Xoá).
class TagRow extends StatelessWidget {
  const TagRow({required this.tag, required this.onTap, super.key});

  final Tag tag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    return Semantics(
      button: true,
      container: true,
      label: s.tagsRowSemantics(tag.name, tag.transactionCount),
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        highlightColor: c.bgSubtle,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Row(
            children: [
              Container(
                width: FreevaSize.iconTile,
                height: FreevaSize.iconTile,
                decoration: BoxDecoration(
                  color: c.tintViolet,
                  borderRadius: BorderRadius.circular(FreevaRadius.xs),
                ),
                child: Icon(
                  LucideIcons.tag,
                  size: FreevaSize.iconChip,
                  color: c.tintVioletFg,
                ),
              ),
              const SizedBox(width: FreevaSpace.s3),
              Expanded(
                child: Text(
                  tag.name,
                  style: FreevaTypography.body.copyWith(color: c.textPrimary),
                ),
              ),
              const SizedBox(width: FreevaSpace.s3),
              Text(
                '${tag.transactionCount}',
                style: FreevaTypography.bodyS.copyWith(
                  color: c.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: FreevaSpace.s3),
              Icon(
                LucideIcons.chevronRight,
                size: FreevaSize.iconXs,
                color: c.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
