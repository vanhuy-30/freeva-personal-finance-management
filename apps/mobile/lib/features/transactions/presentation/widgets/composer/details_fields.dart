import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/theme/tokens.g.dart';
import '../../../../../core/widgets/freeva_text_field.dart';
import '../../../../../core/widgets/settings_group.dart';
import '../../../../../core/widgets/settings_row.dart';
import '../../../../categories/presentation/widgets/category_badge.dart';
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
    final pick = ComposerPickers(context, composer);
    final locale = Localizations.localeOf(context).toString();
    final date = composer.occurredOn.isEmpty
        ? ''
        : TransactionDayHeader.label(
            s,
            composer.occurredOn,
            composer.model.today() ?? '',
            locale,
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsGroup(
          children: [
            if (!composer.transfer)
              SettingsRow(
                icon: categoryIcon(composer.category?.iconToken),
                title: s.txDetailCategory,
                value: composer.category?.name ?? s.txPickCategory,
                onTap: pick.category,
              ),
            SettingsRow(
              icon: LucideIcons.wallet,
              title: s.txDetailWallet,
              value: composer.source?.draft.name ?? s.txPickWallet,
              onTap: pick.wallet,
            ),
            SettingsRow(
              icon: LucideIcons.calendar,
              title: s.txDetailDate,
              value: date,
              onTap: pick.date,
            ),
          ],
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
          const SizedBox(height: FreevaSpace.s3),
        ],
        FreevaTextField(
          label: s.txDetailNotes,
          hint: s.txNotesHint,
          controller: notes,
          onChanged: composer.setNotes,
          maxLines: 3,
        ),
        SectionHeader(s.transactionTags),
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
