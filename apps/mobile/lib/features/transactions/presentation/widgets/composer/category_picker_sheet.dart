import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/text/vietnamese_fold.dart';
import '../../../../../core/theme/tokens.g.dart';
import '../../../../../core/widgets/freeva_sheet.dart';
import '../../../../../core/widgets/selectable_card.dart';
import '../../../../../core/widgets/settings_group.dart';
import '../../../../categories/domain/finance_category.dart';
import '../../../../categories/presentation/widgets/category_badge.dart';
import 'category_parent_group.dart';

/// "Chọn danh mục" (C2.2): search, 4 frequent cards, then each parent row
/// with its children as chips. A parent or a child can be picked; picking
/// closes the sheet.
Future<String?> showCategoryPicker(
  BuildContext context, {
  required List<FinanceCategory> categories,
  required List<FinanceCategory> frequent,
  required String? selected,
}) {
  final s = S.of(context);
  return showFreevaSheet<String>(
    context: context,
    title: s.txPickCategory,
    builder: (_) =>
        _Body(categories: categories, frequent: frequent, selected: selected),
  );
}

class _Body extends StatefulWidget {
  const _Body({
    required this.categories,
    required this.frequent,
    required this.selected,
  });
  final List<FinanceCategory> categories;
  final List<FinanceCategory> frequent;
  final String? selected;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  String query = '';

  bool _match(FinanceCategory c) =>
      query.isEmpty || foldVietnamese(c.name).contains(foldVietnamese(query));

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    void pick(String id) => Navigator.of(context).pop(id);
    final parents = widget.categories.where((x) => x.parentId == null).toList();
    List<FinanceCategory> kids(String id) =>
        widget.categories.where((x) => x.parentId == id).toList();
    final frequent = widget.frequent.where(_match).take(4).toList();
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            onChanged: (v) => setState(() => query = v.trim()),
            decoration: InputDecoration(
              hintText: s.txFindCategory,
              prefixIcon: const Icon(
                LucideIcons.search,
                size: FreevaSize.iconInline,
              ),
            ),
          ),
          if (frequent.isNotEmpty) ...[
            SectionHeader(s.txFrequent),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 3,
              children: [
                for (final cat in frequent)
                  SelectableCard(
                    label: cat.name,
                    icon: categoryIcon(cat.iconToken),
                    selected: cat.id == widget.selected,
                    onTap: () => pick(cat.id),
                  ),
              ],
            ),
          ],
          SectionHeader(s.txFilterAny),
          for (final parent in parents)
            if (_match(parent) || kids(parent.id).any(_match))
              CategoryParentGroup(
                parent: parent,
                children: [
                  for (final kid in kids(parent.id))
                    if (_match(kid) || _match(parent)) kid,
                ],
                selected: widget.selected,
                onPick: pick,
              ),
        ],
      ),
    );
  }
}
