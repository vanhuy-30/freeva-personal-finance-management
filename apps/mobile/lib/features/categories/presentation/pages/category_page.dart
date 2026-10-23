import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/widgets/freeva_icon_button.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../domain/finance_category.dart';
import '../viewmodels/category_view_model.dart';
import '../widgets/category_editor.dart';
import '../widgets/category_list_body.dart';

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

  void _open({FinanceCategory? category}) {
    if (!_ready) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: category == null,
        builder: (_) => CategoryEditor(
          model: model,
          category: category,
          kind: income ? CategoryKind.income : CategoryKind.expense,
        ),
      ),
    );
  }

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
        ),
      ),
    );
  }
}
