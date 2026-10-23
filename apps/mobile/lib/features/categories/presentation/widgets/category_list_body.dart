import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_retry.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/freeva_segmented.dart';
import '../../../../core/widgets/hidden_items_link.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../domain/category_rules.dart';
import '../../domain/finance_category.dart';
import '../viewmodels/category_view_model.dart';
import 'category_group_rows.dart';

/// Body of Danh mục (E, màn 1): Chi · Thu, the groups of that tab, and the
/// hidden categories link.
class CategoryListBody extends StatelessWidget {
  const CategoryListBody({
    required this.model,
    required this.income,
    required this.onTab,
    required this.onOpen,
    required this.onAdd,
    super.key,
  });

  final CategoryViewModel model;
  final bool income;
  final ValueChanged<bool> onTab;
  final ValueChanged<FinanceCategory> onOpen;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final margin = context.screenMargin;
    final empty = model.categories.isEmpty;
    if (empty && model.failure != null && !model.busy) {
      return Center(
        child: ErrorRetry(
          title: s.categoryLoadError,
          message: s.homeErrorBody,
          onRetry: model.load,
        ),
      );
    }
    final groups = categoryGroups(model.categories, income: income);
    final hidden = hiddenCategoryGroups(model.categories).length;
    return RefreshIndicator(
      onRefresh: model.load,
      child: ListView(
        padding: EdgeInsets.fromLTRB(margin, 0, margin, FreevaSpace.s8),
        children: [
          Semantics(
            label: s.categoryTabs,
            child: FreevaSegmented<bool>(
              expand: true,
              selected: income,
              onChanged: onTab,
              segments: [
                FreevaSegment(false, s.categoryTabExpense),
                FreevaSegment(true, s.categoryTabIncome),
              ],
            ),
          ),
          const SizedBox(height: FreevaSpace.s4),
          // Not loaded yet (or just locked): skeleton, never a flash of empty.
          if (empty && (model.busy || !model.options.isReady))
            const SkeletonRows(count: 5)
          else if (groups.isEmpty)
            EmptyState(
              title: s.categoryEmptyTitle,
              message: s.categoryEmptyBody,
              actionLabel: s.categoryAdd,
              onAction: onAdd,
            )
          else
            FreevaCard(
              list: true,
              padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
              child: Column(
                children: [
                  for (final (i, group) in groups.indexed) ...[
                    if (i > 0) Divider(height: 1, color: c.listDivider),
                    CategoryGroupRows(
                      group: group,
                      expanded: model.expanded.contains(group.parent.id),
                      onToggle: () => model.toggleExpanded(group.parent.id),
                      onOpen: onOpen,
                    ),
                  ],
                ],
              ),
            ),
          if (hidden > 0) ...[
            const SizedBox(height: FreevaSpace.s3),
            HiddenItemsLink(
              label: s.categoryHiddenTitle,
              count: hidden,
              onTap: () => context.push('/categories/hidden'),
            ),
          ],
        ],
      ),
    );
  }
}
