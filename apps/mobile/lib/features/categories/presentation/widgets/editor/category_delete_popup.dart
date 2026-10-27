import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.g.dart';
import '../../../../../core/widgets/freeva_button.dart';
import '../../../../../core/widgets/freeva_dialog.dart';
import '../../../../../core/widgets/freeva_picker_field.dart';
import '../../../domain/finance_category.dart';
import '../category_icon_tile.dart';
import 'category_choice_sheet.dart';

/// What the delete popup returns: delete, moving transactions to
/// [replacementId] when there are any.
class CategoryDeleteChoice {
  const CategoryDeleteChoice(this.replacementId);
  final String? replacementId;
}

/// "Xoá “Ăn vặt”?" (E, màn 6). With transactions, they move to the picked
/// category; without, the picker is left out. Null when cancelled.
Future<CategoryDeleteChoice?> showCategoryDeletePopup(
  BuildContext context, {
  required FinanceCategory category,
  required int transactionCount,
  required List<FinanceCategory> targets,
  required String? initialTarget,
}) => showDialog<CategoryDeleteChoice>(
  context: context,
  builder: (_) => _DeletePopup(
    category: category,
    count: transactionCount,
    targets: targets,
    initial: initialTarget,
  ),
);

class _DeletePopup extends StatefulWidget {
  const _DeletePopup({
    required this.category,
    required this.count,
    required this.targets,
    required this.initial,
  });

  final FinanceCategory category;
  final int count;
  final List<FinanceCategory> targets;
  final String? initial;

  @override
  State<_DeletePopup> createState() => _DeletePopupState();
}

class _DeletePopupState extends State<_DeletePopup> {
  late String? target = widget.initial;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final moves = widget.count > 0;
    final chosen = widget.targets.where((t) => t.id == target).firstOrNull;
    return FreevaDialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: FreevaDialogIcon(icon: LucideIcons.trash)),
          const SizedBox(height: 10),
          Semantics(
            header: true,
            child: Text(
              s.categoryDeleteQuestion(widget.category.name),
              textAlign: TextAlign.center,
              style: FreevaTypography.titleL.copyWith(color: c.textPrimary),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            moves ? s.categoryDeleteMove(widget.count) : s.categoryDeleteNoUndo,
            textAlign: TextAlign.center,
            style: FreevaTypography.body.copyWith(
              fontSize: 14,
              color: c.textSecondary,
            ),
          ),
          if (moves) ...[
            const SizedBox(height: FreevaSpace.s4),
            // The sentence above ends in "chuyển sang:", so no label here.
            PickerField(
              label: '',
              compact: true,
              value: chosen?.name ?? s.categoryPickParent,
              placeholder: chosen == null,
              leading: chosen == null
                  ? null
                  : CategoryIconTile(
                      iconToken: chosen.iconToken,
                      colorToken: chosen.colorToken,
                      size: 32,
                    ),
              onTap: () async {
                final id = await showCategoryChoiceSheet(
                  context,
                  title: s.categoryMoveTo,
                  choices: widget.targets,
                  selected: target,
                );
                if (id != null) setState(() => target = id);
              },
            ),
          ],
          const SizedBox(height: FreevaSpace.s4),
          Row(
            children: [
              Expanded(
                child: FreevaButton(
                  label: s.commonCancel,
                  variant: FreevaButtonVariant.secondary,
                  size: FreevaButtonSize.dialog,
                  expand: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: FreevaSpace.s2),
              Expanded(
                child: FreevaButton(
                  label: s.categoryDeleteShort,
                  variant: FreevaButtonVariant.destructive,
                  size: FreevaButtonSize.dialog,
                  expand: true,
                  onPressed: moves && chosen == null
                      ? null
                      : () => Navigator.of(context)
                            .pop(CategoryDeleteChoice(moves ? target : null)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
