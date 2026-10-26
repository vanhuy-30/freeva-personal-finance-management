import 'package:flutter/material.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/text/vietnamese_fold.dart';
import '../../../../../core/theme/tokens.g.dart';
import '../../../../../core/widgets/freeva_sheet.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/widgets/check_mark.dart';
import '../../../../categories/domain/finance_category.dart';
import '../../../../categories/presentation/widgets/category_badge.dart';
import '../../../../categories/presentation/widgets/category_icon_tile.dart';
import '../search_box.dart';
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
    titleGap: FreevaSpace.s4,
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
    final c = context.colors;
    final label = FreevaTypography.bodyS.copyWith(
      fontWeight: FontWeight.w600,
      color: c.textSecondary,
    );
    Widget section(String text) =>
        Semantics(header: true, child: Text(text, style: label));
    // Board: the sheet reaches 112 from the top of the screen.
    final media = MediaQuery.of(context);
    final height =
        media.size.height -
        112 -
        media.padding.top -
        // handle block, title, title gap, bottom padding
        (10 + 4 + 14 + 24 + 16 + 28 + media.padding.bottom);
    return SizedBox(
      height: height.clamp(240, double.infinity),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SearchBox(
            hint: s.txFindCategory,
            filled: true,
            iconSize: FreevaSize.iconSm,
            onChanged: (v) => setState(() => query = v.trim()),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: FreevaSpace.s4),
              children: [
                if (frequent.isNotEmpty) ...[
                  section(s.txFrequent),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < 4; i++) ...[
                        if (i > 0) const SizedBox(width: FreevaSpace.s2),
                        Expanded(
                          child: i < frequent.length
                              ? _FrequentTile(
                                  category: frequent[i],
                                  selected: frequent[i].id == widget.selected,
                                  onTap: () => pick(frequent[i].id),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: FreevaSpace.s5),
                ],
                section(s.txFilterAny),
                const SizedBox(height: 10),
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
          ),
        ],
      ),
    );
  }
}

/// "Hay dùng" tile (board `.fav`): 76 high, radius 20, 32 two-tone icon box
/// over a 12/500 label. Selected: `tint.blue`, 1.5 primary border, white
/// icon box with a primary glyph and a 16 check badge in the corner.
class _FrequentTile extends StatelessWidget {
  const _FrequentTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final FinanceCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, fg) = selected
        ? (c.bgSurface, c.actionPrimary)
        : categoryTwoTone(context, category.colorToken);
    final radius = BorderRadius.circular(FreevaRadius.lg);
    return Semantics(
      button: true,
      selected: selected,
      label: category.name,
      excludeSemantics: true,
      child: Material(
        color: selected ? c.tintBlue : c.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: selected ? c.actionPrimary : c.borderDefault,
            width: selected ? FreevaBorder.selected : FreevaBorder.defaultValue,
          ),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: SizedBox(
            height: 76,
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(FreevaRadius.sm),
                        ),
                        child: Icon(
                          categoryIcon(category.iconToken),
                          size: FreevaSize.iconSm,
                          color: fg,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          category.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: FreevaTypography.label.copyWith(
                            height: 1.25,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.actionPrimary,
                      ),
                      child: Center(
                        child: CheckMark(color: c.textOnAction, size: 10),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
