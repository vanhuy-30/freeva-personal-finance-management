import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../viewmodels/category_view_model.dart';
import '../widgets/category_editor.dart';
import '../widgets/category_labels.dart';
import '../widgets/category_list.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});
  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  late final CategoryViewModel model;
  bool archived = false;
  @override
  void initState() {
    super.initState();
    model = getIt<CategoryViewModel>();
    Future.microtask(model.load);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) {
      final s = S.of(context);
      final canAdd = !model.busy && !model.needsReload && model.options.isReady;
      return Scaffold(
        appBar: AppBar(
          title: Text(s.categoryTitle),
          leading: IconButton(
            tooltip: s.profileBack,
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/home'),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (model.busy) const LinearProgressIndicator(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(s.categoryShowHidden),
                      value: archived,
                      onChanged: (value) => setState(() => archived = value),
                    ),
                    if (model.failure != null)
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          categoryError(s, model.failure!),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    if (model.needsReload) Text(s.categoryReloadRequired),
                    Wrap(
                      spacing: 12,
                      children: [
                        OutlinedButton(
                          onPressed: model.busy ? null : model.load,
                          child: Text(s.profileReload),
                        ),
                        FilledButton.icon(
                          icon: const Icon(Icons.add),
                          label: Text(s.categoryAdd),
                          onPressed: canAdd
                              ? () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        CategoryEditor(model: model),
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CategoryList(model: model, archived: archived),
              ),
            ],
          ),
        ),
      );
    },
  );
}
