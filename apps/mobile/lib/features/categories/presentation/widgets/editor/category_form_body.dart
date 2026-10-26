import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.g.dart';
import '../../../../../core/widgets/field_error_hint.dart';
import '../../../../../core/widgets/freeva_picker_field.dart';
import '../../../../../core/widgets/freeva_segmented.dart';
import '../../../../../core/widgets/freeva_text_field.dart';
import '../../viewmodels/category_form.dart';
import '../category_badge.dart';
import '../category_icon_tile.dart';
import '../category_names.dart';
import 'category_choice_sheet.dart';
import 'category_color_grid.dart';
import 'category_icon_cell.dart';
import 'category_icon_sheet.dart';

/// Fields of Thêm / Sửa danh mục: preview + name, main or sub + "Thuộc",
/// colour grid, icons (quick grid when adding, a field when editing).
class CategoryFormBody extends StatelessWidget {
  const CategoryFormBody({
    required this.form,
    required this.name,
    required this.colors,
    this.actions,
    super.key,
  });

  final CategoryForm form;
  final TextEditingController name;

  /// Palette from `/categories/options`.
  final List<String> colors;

  /// "Ẩn · Xoá" when editing.
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    // CatAdd stacks its blocks 14 apart, CatEdit 16.
    final space = form.isNew ? 14.0 : FreevaSpace.s4;
    final gap = SizedBox(height: space);
    Widget label(String text, {double bottom = 10}) => Padding(
      padding: EdgeInsets.only(left: 4, bottom: bottom),
      child: Text(
        text,
        style: FreevaTypography.bodyS.copyWith(
          fontWeight: FontWeight.w600,
          color: c.textSecondary,
        ),
      ),
    );
    final preview = CategoryIconTile(
      iconToken: form.iconToken,
      colorToken: form.colorToken,
      size: form.isNew ? 60 : 64,
    );
    final nameField = FreevaTextField(
      label: s.categoryName,
      controller: name,
      inputFormatters: [LengthLimitingTextInputFormatter(100)],
      error: form.errors.contains(CategoryFormError.name)
          ? s.categoryNameMissing
          : null,
    );
    final parent = form.parent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (form.isNew)
          Row(
            children: [
              preview,
              const SizedBox(width: 14),
              Expanded(child: nameField),
            ],
          )
        else ...[
          // The board pads the preview 4 above and below.
          Padding(
            padding: const EdgeInsets.symmetric(vertical: FreevaSpace.s1),
            child: Center(child: preview),
          ),
          gap,
          nameField,
        ],
        if (form.canBeChild) ...[
          gap,
          Semantics(
            label: s.categoryTabs,
            child: FreevaSegmented<bool>(
              expand: true,
              style: FreevaSegmentedStyle.raised,
              selected: form.child,
              onChanged: form.setChild,
              segments: [
                FreevaSegment(false, s.categoryLevelMain),
                FreevaSegment(true, s.categoryLevelChild),
              ],
            ),
          ),
        ],
        if (form.child) ...[
          gap,
          PickerField(
            label: s.categoryParentField,
            value: parent?.name ?? s.categoryPickParent,
            placeholder: parent == null,
            chevronSize: FreevaSize.iconSm,
            leading: parent == null
                ? null
                : CategoryIconTile(
                    iconToken: parent.iconToken,
                    colorToken: parent.colorToken,
                    size: 32,
                  ),
            onTap: () async {
              final id = await showCategoryChoiceSheet(
                context,
                title: s.categoryParentSheet,
                choices: form.parentChoices,
                selected: form.parentId,
              );
              if (id != null) form.setParent(id);
            },
          ),
          if (form.errors.contains(CategoryFormError.parent))
            FieldErrorHint(s.categoryParentMissing),
        ],
        gap,
        // Swatch rows are 44 touch boxes around 34 dots: 5 of each box sits
        // above the first dot, so the label keeps 10 to the dot.
        label(s.categoryColor, bottom: 5),
        CategoryColorGrid(
          colors: colors,
          selected: form.colorToken,
          onChanged: form.setColor,
        ),
        // …and 5 below the last dot.
        SizedBox(height: space - 5),
        if (form.isNew) ...[
          label(s.categoryIcon),
          _QuickIcons(form: form),
        ] else
          PickerField(
            label: s.categoryIcon,
            value: categoryIconLabel(s, form.iconToken),
            chevronSize: FreevaSize.iconSm,
            leading: CategoryIconTile(
              iconToken: form.iconToken,
              colorToken: form.colorToken,
              size: 32,
            ),
            onTap: () => _pickIcon(context, form),
          ),
        if (actions != null) ...[
          SizedBox(height: space + FreevaSpace.s1),
          actions!,
        ],
      ],
    );
  }
}

Future<void> _pickIcon(BuildContext context, CategoryForm form) async {
  final token = await showCategoryIconSheet(
    context,
    selected: form.iconToken,
    colorToken: form.colorToken,
  );
  if (token != null) form.setIcon(token);
}

/// 11 common icons and "…" for the rest. A chosen icon that is not among
/// them takes the first place, so the choice is always visible.
class _QuickIcons extends StatelessWidget {
  const _QuickIcons({required this.form});

  final CategoryForm form;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final picked = form.iconToken;
    final tokens = picked == null || categoryQuickIcons.contains(picked)
        ? categoryQuickIcons
        : [picked, ...categoryQuickIcons.take(categoryQuickIcons.length - 1)];
    return IconGridRows(
      cells: [
        for (final token in tokens)
          CategoryIconCell(
            icon: categoryIcon(token),
            label: categoryIconLabel(s, token),
            selected: token == picked,
            colorToken: form.colorToken,
            onTap: () => form.setIcon(token),
          ),
        Semantics(
          container: true,
          button: true,
          label: s.categoryMoreIcons,
          onTap: () => _pickIcon(context, form),
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _pickIcon(context, form),
            child: Container(
              height: FreevaSize.touch,
              decoration: BoxDecoration(
                color: c.bgSurface,
                borderRadius: BorderRadius.circular(FreevaRadius.smd),
                border: Border.all(color: c.borderDefault),
              ),
              child: Icon(
                LucideIcons.ellipsis,
                size: FreevaSize.iconSm,
                color: c.actionPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
