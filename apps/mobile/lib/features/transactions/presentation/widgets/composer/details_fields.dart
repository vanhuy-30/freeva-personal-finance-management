import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.g.dart';
import '../../../../../core/widgets/freeva_card.dart';
import '../../../../../core/widgets/freeva_text_field.dart';
import '../../viewmodels/transaction_composer.dart';
import '../transaction_day_header.dart';
import 'composer_pickers.dart';
import 'tag_edit_chips.dart';

/// C2.3 (also the edit screen): Danh mục · Ví · Thời gian, Cửa hàng,
/// Ghi chú and tag chips with × and "+ Thêm nhãn".
class DetailsFields extends StatelessWidget {
  const DetailsFields({
    required this.composer,
    required this.merchant,
    required this.notes,
    super.key,
  });

  final TransactionComposer composer;
  final TextEditingController merchant;
  final TextEditingController notes;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final pick = ComposerPickers(context, composer);
    final locale = Localizations.localeOf(context).toString();
    final date = composer.occurredOn.isEmpty
        ? ''
        : TransactionDayHeader.when(
            s,
            composer.occurredOn,
            composer.model.today() ?? '',
            locale,
            time: composer.occurredTime,
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FreevaCard(
          list: true,
          padding: const EdgeInsets.symmetric(horizontal: FreevaSpace.s4),
          child: Column(
            children: [
              for (final (i, row) in [
                if (!composer.transfer)
                  (
                    s.txDetailCategory,
                    composer.category?.name ?? s.txPickCategory,
                    pick.category,
                  ),
                (
                  s.txDetailWallet,
                  composer.source?.draft.name ?? s.txPickWallet,
                  pick.wallet,
                ),
                (s.txDetailDate, date, pick.when),
              ].indexed) ...[
                if (i > 0) Divider(height: 1, color: c.listDivider),
                _PickRow(label: row.$1, value: row.$2, onTap: row.$3),
              ],
            ],
          ),
        ),
        const SizedBox(height: FreevaSpace.s4),
        if (!composer.transfer) ...[
          FreevaTextField(
            label: s.txMerchantLabel,
            hint: s.txMerchantHint,
            controller: merchant,
            onChanged: composer.setMerchant,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: FreevaSpace.s4),
        ],
        FreevaTextField(
          label: s.txDetailNotes,
          hint: s.txNotesHint,
          controller: notes,
          onChanged: composer.setNotes,
          maxLines: 2,
        ),
        const SizedBox(height: FreevaSpace.s4),
        Padding(
          padding: const EdgeInsets.only(left: FreevaSpace.s1),
          child: Semantics(
            header: true,
            child: Text(
              s.transactionTags,
              style: FreevaTypography.bodyS.copyWith(
                fontWeight: FontWeight.w600,
                color: c.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(height: FreevaSpace.s2),
        TagEditChips(
          names: {for (final t in composer.model.tags) t.id: t.name},
          ids: composer.tagIds,
          onRemove: (id) => composer.setTags([...composer.tagIds]..remove(id)),
          onAdd: pick.tags,
        ),
      ],
    );
  }
}

/// Board row: 52 high, key 84 wide 14 muted, value 15/500 right-aligned,
/// 16 chevron. Opens a picker.
class _PickRow extends StatelessWidget {
  const _PickRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: '$label, $value',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Row(
            children: [
              SizedBox(
                width: 84,
                child: Text(
                  label,
                  style: FreevaTypography.bodyM.copyWith(
                    color: c.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: FreevaSpace.s3),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: FreevaTypography.body.copyWith(
                    fontWeight: FontWeight.w500,
                    color: c.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: FreevaSpace.s3),
              Icon(
                LucideIcons.chevronRight,
                size: FreevaSize.iconChip,
                color: c.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
