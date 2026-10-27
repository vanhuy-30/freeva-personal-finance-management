import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../auth/presentation/widgets/auth_gate.dart';
import '../../domain/category_rules.dart';
import '../../domain/finance_category.dart';
import '../viewmodels/category_form.dart';
import '../viewmodels/category_view_model.dart';
import '../widgets/category_labels.dart';
import '../widgets/editor/category_delete_popup.dart';
import '../widgets/editor/category_edit_actions.dart';
import '../widgets/editor/category_form_body.dart';

enum CategoryEditResult { saved, hidden, deleted }

/// Opens "Thêm danh mục" ([category] null, on the [kind] tab) or "Sửa danh
/// mục" as a modal.
Future<CategoryEditResult?> openCategoryEditor(
  BuildContext context,
  CategoryViewModel model, {
  FinanceCategory? category,
  CategoryKind kind = CategoryKind.expense,
}) {
  if (model.busy || model.needsReload || !model.options.isReady) {
    return Future.value();
  }
  return Navigator.of(context).push<CategoryEditResult>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) =>
          CategoryEditorPage(model: model, category: category, kind: kind),
    ),
  );
}

/// Thêm / Sửa danh mục (E, màn 2 and 5). Locking or signing out closes it
/// and drops the draft.
class CategoryEditorPage extends StatefulWidget {
  const CategoryEditorPage({
    required this.model,
    this.category,
    this.kind = CategoryKind.expense,
    super.key,
  });

  final CategoryViewModel model;
  final FinanceCategory? category;
  final CategoryKind kind;

  @override
  State<CategoryEditorPage> createState() => _CategoryEditorPageState();
}

class _CategoryEditorPageState extends State<CategoryEditorPage> {
  CategoryViewModel get model => widget.model;
  late final CategoryForm form = CategoryForm(
    categories: model.categories,
    clientId: model.newClientId(),
    tabKind: widget.kind,
    category: widget.category,
  );
  late final name = TextEditingController(text: widget.category?.name ?? '');

  /// Errors from earlier screens are not this form's; show only after a try.
  bool _tried = false;

  @override
  void initState() {
    super.initState();
    model.addListener(_changed);
  }

  void _changed() {
    // Lock / sign-out clears the options: drop the draft and its version.
    if (model.options.isReady) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        Navigator.of(context).pop();
      }
    });
  }

  void _close(CategoryEditResult result) {
    if (mounted) Navigator.of(context).pop(result);
  }

  Future<void> _save() async {
    final draft = form.build(name.text);
    if (draft == null) return;
    setState(() => _tried = true);
    final ok = await model.save(
      draft,
      form.clientId,
      category: widget.category,
    );
    if (!ok) return;
    // A new subcategory shows right away under its opened parent.
    if (draft.parentId != null) model.expand(draft.parentId!);
    _close(CategoryEditResult.saved);
  }

  Future<void> _hide() async {
    setState(() => _tried = true);
    if (await model.archive(widget.category!)) {
      _close(CategoryEditResult.hidden);
    }
  }

  Future<void> _delete() async {
    final category = widget.category!;
    setState(() => _tried = true);
    final count = await model.usage(category);
    if (count == null || !mounted) return;
    final targets = [
      for (final group in categoryGroups(
        model.categories,
        income: category.kind == CategoryKind.income,
      )) ...[group.parent, ...group.children],
    ].where((c) => c.id != category.id).toList();
    final choice = await showCategoryDeletePopup(
      context,
      category: category,
      transactionCount: count,
      targets: targets,
      initialTarget: category.parentId ?? targets.firstOrNull?.id,
    );
    if (choice == null) return;
    final ok = await model.remove(
      category,
      replacementCategoryId: choice.replacementId,
    );
    if (ok) _close(CategoryEditResult.deleted);
  }

  @override
  void dispose() {
    model.removeListener(_changed);
    form.dispose();
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final margin = context.screenMargin;
    return AuthGate(
      child: ListenableBuilder(
        listenable: Listenable.merge([model, form]),
        builder: (context, _) {
          final category = widget.category;
          final failure = _tried ? model.failure : null;
          final children = category == null
              ? 0
              : model.categories.where((c) => c.parentId == category.id).length;
          final activeChildren =
              category != null &&
              categoryHasActiveChild(category, model.categories);
          return Scaffold(
            appBar: FreevaTopBar(
              title: category == null ? s.categoryAdd : s.categoryEdit,
              kind: FreevaTopBarKind.modal,
            ),
            body: ListView(
              // 6 / 8 under the 60 top bar = the board's 14 (add) / 16
              // (edit) under the close button.
              padding: EdgeInsets.fromLTRB(
                margin,
                category == null ? 6 : FreevaSpace.s2,
                margin,
                FreevaSpace.s6,
              ),
              children: [
                CategoryFormBody(
                  form: form,
                  name: name,
                  colors: model.options.colorTokens,
                  actions: category == null
                      ? null
                      : CategoryEditActions(
                          onHide: model.busy || activeChildren ? null : _hide,
                          onDelete: model.busy || children > 0 ? null : _delete,
                          children: children,
                        ),
                ),
              ],
            ),
            // The save button sits 28 above the screen edge (or the safe
            // area, whichever is lower).
            bottomNavigationBar: SafeArea(
              minimum: const EdgeInsets.only(bottom: 28),
              child: Padding(
                padding: EdgeInsets.fromLTRB(margin, FreevaSpace.s2, margin, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (failure != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: FreevaSpace.s2),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            categoryError(s, failure),
                            textAlign: TextAlign.center,
                            style: FreevaTypography.bodyS.copyWith(
                              color: c.statusDanger,
                            ),
                          ),
                        ),
                      ),
                    FreevaButton(
                      label: category == null
                          ? s.categorySave
                          : s.categorySaveChanges,
                      size: FreevaButtonSize.l,
                      expand: true,
                      loading: model.busy,
                      onPressed: model.busy || model.needsReload ? null : _save,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
