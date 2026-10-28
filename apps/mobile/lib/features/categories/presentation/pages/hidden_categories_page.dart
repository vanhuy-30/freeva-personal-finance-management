import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../domain/category_rules.dart';
import '../../domain/finance_category.dart';
import '../viewmodels/category_view_model.dart';
import '../widgets/category_labels.dart';
import '../widgets/hidden_category_row.dart';

/// Danh mục đã ẩn (E, màn 7). Restoring a main category also restores its
/// hidden subcategories.
class HiddenCategoriesPage extends StatelessWidget {
  const HiddenCategoriesPage({super.key});

  Future<void> _restore(
    BuildContext context,
    CategoryViewModel model,
    FinanceCategory category,
  ) async {
    final s = S.of(context);
    final ok = await model.restore(category);
    if (!context.mounted) return;
    final failure = model.failure;
    showFreevaToast(
      context,
      message: ok || failure == null
          ? s.categoryRestored(category.name)
          : categoryError(s, failure),
      icon: ok ? LucideIcons.check : null,
      aboveNav: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final model = getIt<CategoryViewModel>();
    final margin = context.screenMargin;
    return Scaffold(
      appBar: FreevaTopBar(
        title: s.categoryHiddenTitle,
        onLeading: () => context.popOrGo('/categories'),
      ),
      body: ListenableBuilder(
        listenable: model,
        builder: (context, _) {
          final groups = hiddenCategoryGroups(model.categories);
          return ListView(
            padding: EdgeInsets.fromLTRB(
              margin,
              FreevaSpace.s2,
              margin,
              FreevaSpace.s8,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, FreevaSpace.s4),
                child: Text(
                  s.categoryHiddenHint,
                  style: FreevaTypography.body.copyWith(
                    fontSize: 14,
                    color: c.textSecondary,
                  ),
                ),
              ),
              if (groups.isEmpty)
                EmptyState(title: s.categoryHiddenEmpty)
              else
                FreevaCard(
                  list: true,
                  padding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
                  child: Column(
                    children: [
                      for (final (i, group) in groups.indexed) ...[
                        if (i > 0) Divider(height: 1, color: c.listDivider),
                        HiddenCategoryRow(
                          group: group,
                          busy: model.busy,
                          onRestore: () =>
                              _restore(context, model, group.parent),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
