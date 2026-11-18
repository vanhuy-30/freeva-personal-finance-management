import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../domain/app_feature_index.dart';

/// "Chức năng" under the search box: screens of the app that match what was
/// typed (or the usual shortcuts), each opens its screen.
class SearchFeatureList extends StatelessWidget {
  const SearchFeatureList({
    required this.title,
    required this.features,
    super.key,
  });

  final String title;
  final List<AppFeature> features;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: FreevaTypography.bodyS.copyWith(
              fontWeight: FontWeight.w600,
              color: c.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: FreevaSpace.s2),
        FreevaCard(
          list: true,
          padding: const EdgeInsets.symmetric(horizontal: FreevaSpace.s4),
          child: Column(
            children: [
              for (final (i, f) in features.indexed) ...[
                if (i > 0) Divider(height: 1, color: c.listDivider),
                Semantics(
                  button: true,
                  label: f.label(s),
                  excludeSemantics: true,
                  child: InkWell(
                    onTap: () => context.push(f.route),
                    child: SizedBox(
                      height: FreevaSize.row,
                      child: Row(
                        children: [
                          Icon(
                            f.icon,
                            size: FreevaSize.iconInline,
                            color: c.textOnWash,
                          ),
                          const SizedBox(width: FreevaSpace.s3),
                          Expanded(
                            child: Text(
                              f.label(s),
                              style: FreevaTypography.body.copyWith(
                                fontWeight: FontWeight.w500,
                                color: c.textPrimary,
                              ),
                            ),
                          ),
                          Icon(
                            LucideIcons.chevronRight,
                            size: FreevaSize.iconChip,
                            color: c.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
