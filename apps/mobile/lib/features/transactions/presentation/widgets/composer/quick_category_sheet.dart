import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.g.dart';
import '../../../../../core/widgets/freeva_button.dart';
import '../../../../../core/widgets/freeva_sheet.dart';
import '../../../../../core/widgets/freeva_text_field.dart';
import '../../../../categories/domain/category_use_cases.dart';
import '../../../../categories/domain/finance_category.dart';
import '../../../../server_config/domain/app_limits.dart';
import '../../../../sync/domain/sync_queue.dart';

/// "Tạo danh mục" over the category picker: a name is all it needs. The new
/// main category takes the kind of the transaction being recorded. Returns it,
/// or null when closed.
Future<FinanceCategory?> showQuickCategorySheet(
  BuildContext context, {
  required CategoryKind kind,
  required List<FinanceCategory> categories,
  String initialName = '',
}) => showFreevaSheet<FinanceCategory>(
  context: context,
  scrollable: false,
  title: S.of(context).txNewCategory,
  builder: (_) =>
      _Body(kind: kind, categories: categories, initialName: initialName),
);

class _Body extends StatefulWidget {
  const _Body({
    required this.kind,
    required this.categories,
    required this.initialName,
  });

  final CategoryKind kind;
  final List<FinanceCategory> categories;
  final String initialName;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  late final TextEditingController _name = TextEditingController(
    text: widget.initialName,
  );
  // Kept for the whole sheet, so a retry after a dropped connection is not
  // created twice.
  final String _clientId = newSyncOpId();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final s = S.of(context);
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = s.txNewCategoryNameHint);
      return;
    }
    if (widget.categories.any(
      (c) => c.name.toLowerCase() == name.toLowerCase(),
    )) {
      setState(() => _error = s.txNewCategoryExists);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await getIt<CategoryUseCases>().save(
      CategoryDraft(name: name, kind: widget.kind),
      widget.categories,
      const CategoryOptions(),
      clientId: _clientId,
    );
    if (!mounted) return;
    result.fold(
      (_) => setState(() {
        _saving = false;
        _error = s.txNewCategoryFailed;
      }),
      (created) => Navigator.of(context).pop(created),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FreevaTextField(
          label: s.txNewCategoryName,
          controller: _name,
          leadingIcon: LucideIcons.tag,
          error: _error,
          maxLength:
              getIt<AppLimitsSource>().requireLimits.categoryNameMaxLength,
          textInputAction: TextInputAction.done,
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          onSubmitted: (_) => _create(),
        ),
        const SizedBox(height: FreevaSpace.s2),
        Text(
          widget.kind == CategoryKind.income
              ? s.txNewCategoryNoteIncome
              : s.txNewCategoryNoteExpense,
          style: FreevaTypography.bodyS.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: FreevaSpace.s5),
        FreevaButton(
          label: s.txNewCategoryCreate,
          size: FreevaButtonSize.l,
          expand: true,
          loading: _saving,
          onPressed: _saving ? null : _create,
        ),
      ],
    );
  }
}
