import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../domain/finance_category.dart';
import '../viewmodels/category_view_model.dart';
import 'category_fields.dart';
import 'category_labels.dart';

class CategoryEditorForm extends StatefulWidget {
  const CategoryEditorForm({required this.model, this.category, super.key});
  final CategoryViewModel model;
  final FinanceCategory? category;
  @override
  State<CategoryEditorForm> createState() => _CategoryEditorFormState();
}

class _CategoryEditorFormState extends State<CategoryEditorForm> {
  final name = TextEditingController();
  late String clientId;
  String? parentId, colorToken, iconToken;
  bool initialized = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (initialized) return;
    initialized = true;
    final category = widget.category;
    clientId = widget.model.newClientId();
    name.text = category?.name ?? '';
    parentId = category?.parentId;
    colorToken = category?.colorToken;
    iconToken = category?.iconToken;
  }

  Future<void> save() async {
    final ok = await widget.model.save(
      CategoryDraft(
        name: name.text,
        parentId: parentId,
        colorToken: colorToken,
        iconToken: iconToken,
      ),
      clientId,
      category: widget.category,
    );
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.model,
    builder: (context, _) {
      final s = S.of(context), model = widget.model;
      final locked = model.busy || model.needsReload;
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (model.busy) const LinearProgressIndicator(),
            AbsorbPointer(
              absorbing: locked,
              child: CategoryFields(
                name: name,
                parentId: parentId,
                colorToken: colorToken,
                iconToken: iconToken,
                selfId: widget.category?.id,
                categories: model.categories,
                options: model.options,
                onParent: (value) => setState(() => parentId = value),
                onColor: (value) => setState(() => colorToken = value),
                onIcon: (value) => setState(() => iconToken = value),
              ),
            ),
            if (widget.category?.isSystem == true) Text(s.categorySystem),
            if (model.failure != null)
              Semantics(
                liveRegion: true,
                child: Text(
                  categoryError(s, model.failure!),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (model.needsReload) Text(s.categoryReloadRequired),
            FilledButton(
              onPressed: locked ? null : save,
              child: Text(s.profileSave),
            ),
          ],
        ),
      );
    },
  );
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }
}
