import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/freeva_sheet.dart';
import '../../../../core/widgets/freeva_switch.dart';
import '../../../categories/domain/finance_category.dart';
import '../../../categories/presentation/widgets/category_badge.dart';
import '../../../transactions/presentation/widgets/composer/category_picker_sheet.dart';
import '../viewmodels/import_view_model.dart';
import 'import_category_tile.dart';

/// What "Xong" hands back.
typedef ImportCategoryPick = ({String categoryId, bool applyToMerchant});

/// Board R.3 "Đổi danh mục" over the preview: merchant and "03/11 · 45.000 ·
/// Tiền mặt", the suggested tile, a 2-column grid of three other categories
/// plus "Tất cả" (the full picker), the "Áp dụng cho N khoản ở đây" switch
/// and "Xong". Null when dismissed or nothing was picked.
Future<ImportCategoryPick?> showImportCategorySheet(
  BuildContext context, {
  required ImportCategoryChoice choice,
  required int digits,
}) => showFreevaSheet<ImportCategoryPick>(
  context: context,
  builder: (_) => _Body(choice: choice, digits: digits),
);

class _Body extends StatefulWidget {
  const _Body({required this.choice, required this.digits});
  final ImportCategoryChoice choice;
  final int digits;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  late String? selected = widget.choice.selectedId;
  late List<FinanceCategory> quick = widget.choice.quick;
  bool applyAll = true;

  ImportCategoryChoice get choice => widget.choice;
  bool get showSwitch =>
      choice.sameMerchantCount > 1 &&
      (choice.row.merchant?.trim().isNotEmpty ?? false);

  Future<void> _all() async {
    final id = await showCategoryPicker(
      context,
      categories: choice.fitting,
      frequent: choice.frequent,
      selected: selected,
    );
    if (id == null || !mounted) return;
    setState(() {
      selected = id;
      final picked = choice.fitting.where((c) => c.id == id).firstOrNull;
      final known =
          id == choice.suggestion?.categoryId || quick.any((c) => c.id == id);
      if (picked != null && !known) quick = [picked, ...quick].take(3).toList();
    });
  }

  void _done() {
    final id = selected;
    Navigator.of(context).pop<ImportCategoryPick>(
      id == null
          ? null
          : (categoryId: id, applyToMerchant: showSwitch && applyAll),
    );
  }

  String _subtitle(BuildContext context) {
    final row = choice.row;
    final locale = Localizations.localeOf(context).toString();
    final on = row.occurredOn;
    return [
      if (on != null) '${on.substring(8, 10)}/${on.substring(5, 7)}',
      if (row.amountMinor != null)
        formatMoneyText(row.amountMinor!, widget.digits, locale),
      if (choice.walletName != null) choice.walletName!,
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final suggestion = choice.suggestion;
    final merchant = choice.row.merchant?.trim() ?? '';
    Widget section(String text) => Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: FreevaSpace.s1),
        child: Text(
          text.toUpperCase(),
          style: FreevaTypography.sectionLabel.copyWith(
            height: 1.2,
            color: c.textSecondary,
          ),
        ),
      ),
    );
    final tiles = <Widget>[
      for (final cat in quick)
        ImportCategoryTile(
          label: cat.name,
          icon: categoryIcon(cat.iconToken),
          selected: selected == cat.id,
          onTap: () => setState(() => selected = cat.id),
        ),
      ImportCategoryTile(
        label: s.transactionAll,
        icon: LucideIcons.layoutGrid,
        selected: false,
        onTap: _all,
      ),
    ];
    return Semantics(
      container: true,
      label: s.importPickSheetLabel,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Board: 16 from the handle; the sheet body gives 14.
            const SizedBox(height: 2),
            Semantics(
              header: true,
              child: Text(
                choice.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                // Board line heights are the font's own (about 1.2).
                style: FreevaTypography.titleL.copyWith(
                  height: 1.2,
                  color: c.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _subtitle(context),
              style: FreevaTypography.bodyS.copyWith(
                height: 1.2,
                color: c.textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: FreevaSpace.s4),
            if (suggestion != null) ...[
              section(s.importPickSuggested),
              const SizedBox(height: FreevaSpace.s2),
              ImportCategoryTile(
                label: suggestion.categoryName,
                icon: categoryIcon(suggestion.iconToken),
                selected: selected == suggestion.categoryId,
                onTap: () => setState(() => selected = suggestion.categoryId),
              ),
              const SizedBox(height: FreevaSpace.s4),
            ],
            section(
              suggestion != null ? s.importPickOther : s.importPickCategory,
            ),
            const SizedBox(height: FreevaSpace.s2),
            for (var i = 0; i < tiles.length; i += 2) ...[
              if (i > 0) const SizedBox(height: FreevaSpace.s2),
              Row(
                children: [
                  Expanded(child: tiles[i]),
                  const SizedBox(width: FreevaSpace.s2),
                  Expanded(
                    child: i + 1 < tiles.length
                        ? tiles[i + 1]
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ],
            if (showSwitch) ...[
              const SizedBox(height: FreevaSpace.s4),
              _ApplySwitch(
                count: choice.sameMerchantCount,
                merchant: merchant,
                value: applyAll,
                onChanged: (v) => setState(() => applyAll = v),
              ),
            ],
            const SizedBox(height: FreevaSpace.s4),
            FreevaButton(
              label: s.importPickDone,
              size: FreevaButtonSize.l,
              expand: true,
              onPressed: _done,
            ),
          ],
        ),
      ),
    );
  }
}

/// "Áp dụng cho 6 khoản ở đây" / "Các khoản Highlands Coffee trong tệp".
class _ApplySwitch extends StatelessWidget {
  const _ApplySwitch({
    required this.count,
    required this.merchant,
    required this.value,
    required this.onChanged,
  });
  final int count;
  final String merchant;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final title = s.importApplySame(count);
    return FreevaCard(
      list: true,
      padding: const EdgeInsets.symmetric(
        horizontal: FreevaSpace.s4,
        vertical: 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: FreevaTypography.body.copyWith(
                    fontWeight: FontWeight.w500,
                    color: c.textPrimary,
                  ),
                ),
                Text(
                  s.importApplySameHint(merchant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FreevaTypography.label.copyWith(
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          FreevaSwitch(value: value, onChanged: onChanged, label: title),
        ],
      ),
    );
  }
}
