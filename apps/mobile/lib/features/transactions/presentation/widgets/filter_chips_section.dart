import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_chip.dart';
import '../../domain/transaction_filter.dart';
import '../viewmodels/transaction_view_model.dart';

/// Time presets and wallet chips (choose several) of the filter sheet.
class FilterChipsSection extends StatelessWidget {
  const FilterChipsSection({
    required this.model,
    required this.draft,
    required this.onChanged,
    required this.onPickPeriod,
    super.key,
  });

  final TransactionViewModel model;
  final TransactionFilter draft;
  final ValueChanged<TransactionFilter> onChanged;
  final ValueChanged<PeriodPreset> onPickPeriod;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    // Board `.lb`: sentence case 13/600, 20 above, 10 to the chips.
    final label = FreevaTypography.bodyS.copyWith(
      fontWeight: FontWeight.w600,
      color: context.colors.textSecondary,
    );
    Widget title(String text) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Semantics(header: true, child: Text(text, style: label)),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        title(s.txFilterPeriod),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (p, text) in [
              (PeriodPreset.thisWeek, s.txPeriodThisWeek),
              (PeriodPreset.thisMonth, s.txPeriodThisMonth),
              (PeriodPreset.lastMonth, s.txPeriodLastMonth),
              (PeriodPreset.custom, s.txPeriodCustom),
            ])
              FreevaChip(
                label: text,
                icon: p == PeriodPreset.custom ? LucideIcons.calendar : null,
                selected: draft.period == p,
                onTap: () => onPickPeriod(p),
              ),
          ],
        ),
        title(s.txFilterWallets),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final wallet in model.wallets.where((w) => !w.archived))
              FreevaChip(
                label: wallet.draft.name,
                selected: draft.accountIds.contains(wallet.id),
                onTap: () {
                  final ids = {...draft.accountIds};
                  ids.contains(wallet.id)
                      ? ids.remove(wallet.id)
                      : ids.add(wallet.id);
                  onChanged(draft.copyWith(accountIds: ids));
                },
              ),
          ],
        ),
      ],
    );
  }
}
