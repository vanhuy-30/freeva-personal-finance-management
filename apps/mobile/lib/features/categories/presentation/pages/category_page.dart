import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/widgets/freeva_icon_button.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../domain/finance_category.dart';
import '../viewmodels/category_view_model.dart';
import '../../domain/category_rules.dart';
import '../widgets/category_delete_flow.dart';
import '../widgets/category_list_body.dart';
import 'category_editor_page.dart';

/// Danh mục (E, màn 1). A pushed screen, so no bottom nav.
class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});
  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  late final CategoryViewModel model = getIt<CategoryViewModel>();
  bool income = false;

  @override
  void initState() {
    super.initState();
    model.addListener(_changed);
    Future.microtask(model.load);
  }

  /// A write that hit a conflict leaves the list stale: fetch it again.
  void _changed() {
    if (model.needsReload && !model.busy) Future.microtask(model.load);
  }

  @override
  void dispose() {
    model.removeListener(_changed);
    super.dispose();
  }

  bool get _ready => !model.busy && !model.needsReload && model.options.isReady;

  Future<void> _open({FinanceCategory? category}) async {
    if (!_ready) return;
    final result = await openCategoryEditor(
      context,
      model,
      category: category,
      kind: income ? CategoryKind.income : CategoryKind.expense,
    );
    if (!mounted || category == null || result == null) return;
    switch (result) {
      case CategoryEditResult.saved:
        break;
      case CategoryEditResult.hidden:
        _toastHidden(category);
      case CategoryEditResult.deleted:
        _toastDeleted(category);
    }
  }

  // Hidden without asking; "Hoàn tác" restores it right away.
  void _toastHidden(FinanceCategory category) {
    final s = S.of(context);
    showFreevaToast(
      context,
      message: s.categoryHiddenToast(category.name),
      actionLabel: s.commonUndo,
      onAction: () {
        final hidden = model.categories
            .where((c) => c.id == category.id)
            .firstOrNull;
        if (hidden != null && hidden.archived) model.restore(hidden);
      },
      aboveNav: false,
    );
  }

  void _toastDeleted(FinanceCategory category) => showFreevaToast(
    context,
    message: S.of(context).categoryDeletedToast(category.name),
    aboveNav: false,
  );

  /// Swipe "Ẩn": the same rule as the editor (no visible subcategory left).
  Future<void> _swipeHide(FinanceCategory category) async {
    if (!_ready) return;
    if (categoryHasActiveChild(category, model.categories)) {
      return _blocked(category);
    }
    if (await model.archive(category) && mounted) _toastHidden(category);
  }

  /// Swipe "Xoá": asks where its transactions go, as the editor does.
  Future<void> _swipeDelete(FinanceCategory category) async {
    if (!_ready) return;
    if (model.categories.any((c) => c.parentId == category.id)) {
      return _blocked(category);
    }
    if (await confirmAndDeleteCategory(context, model, category) && mounted) {
      _toastDeleted(category);
    }
  }

  void _blocked(FinanceCategory category) => showFreevaToast(
    context,
    message: S
        .of(context)
        .categoryChildrenBlock(
          model.categories.where((c) => c.parentId == category.id).length,
        ),
    aboveNav: false,
  );

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) => Scaffold(
        appBar: FreevaTopBar(
          title: s.categoryTitle,
          onLeading: () => context.popOrGo('/home'),
          action: FreevaIconButton(
            icon: LucideIcons.plus,
            label: s.categoryAdd,
            onPressed: model.options.isReady && !model.needsReload
                ? _open
                : null,
          ),
        ),
        body: CategoryListBody(
          model: model,
          income: income,
          onTab: (value) => setState(() => income = value),
          onOpen: (category) => _open(category: category),
          onAdd: _open,
          onHide: _swipeHide,
          onDelete: _swipeDelete,
        ),
      ),
    );
  }
}
