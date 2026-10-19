import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../auth/presentation/widgets/auth_gate.dart';
import '../../domain/finance_category.dart';
import '../viewmodels/category_view_model.dart';
import 'category_editor_form.dart';

class CategoryEditor extends StatefulWidget {
  const CategoryEditor({required this.model, this.category, super.key});
  final CategoryViewModel model;
  final FinanceCategory? category;
  @override
  State<CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends State<CategoryEditor> {
  @override
  void initState() {
    super.initState();
    widget.model.addListener(_changed);
  }

  void _changed() {
    if (!widget.model.options.isReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ModalRoute.of(context)?.isCurrent == true) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  @override
  void dispose() {
    widget.model.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AuthGate(
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          widget.category == null
              ? S.of(context).categoryAdd
              : S.of(context).categoryEdit,
        ),
      ),
      body: CategoryEditorForm(model: widget.model, category: widget.category),
    ),
  );
}
