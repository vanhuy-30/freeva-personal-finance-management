import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../domain/tag.dart';

/// One tag: icon, name, how many transactions, and a menu for rename/delete.
/// Tapping the row opens the transactions with that tag.
class TagRow extends StatelessWidget {
  const TagRow({
    required this.tag,
    required this.onOpen,
    required this.onMore,
    super.key,
  });

  final Tag tag;
  final VoidCallback onOpen;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    return Row(
      children: [
        Expanded(
          child: Semantics(
            button: true,
            container: true,
            label: s.tagsRowSemantics(tag.name, tag.transactionCount),
            excludeSemantics: true,
            onTap: onOpen,
            child: InkWell(
              onTap: onOpen,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Padding(
                  padding: const EdgeInsets.only(left: FreevaSpace.s4),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: c.bgSubtle,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          LucideIcons.tag,
                          size: 18,
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(width: FreevaSpace.s3),
                      Expanded(
                        child: Text(
                          tag.name,
                          style: FreevaTypography.body.copyWith(
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '${tag.transactionCount}',
                        style: FreevaTypography.body.copyWith(
                          fontSize: 14,
                          color: c.textSecondary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: FreevaSpace.s1),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: s.tagsMore(tag.name),
          onPressed: onMore,
          icon: Icon(
            LucideIcons.ellipsis,
            size: FreevaSize.iconInline,
            color: c.textSecondary,
          ),
        ),
      ],
    );
  }
}
