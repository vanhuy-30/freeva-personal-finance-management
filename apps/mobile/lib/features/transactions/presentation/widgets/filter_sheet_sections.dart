import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../domain/transaction_filter.dart';
import '../viewmodels/transaction_view_model.dart';
import 'filter_pick_sheet.dart';
import 'filter_chips_section.dart';
import 'filter_select_field.dart';

/// Time · Wallets · Categories · Tags · Deleted.
class FilterSheetSections extends StatelessWidget {
  const FilterSheetSections({
    required this.model,
    required this.draft,
    required this.deleted,
    required this.onChanged,
    required this.onOpenDeleted,
    super.key,
  });

  final TransactionViewModel model;
  final TransactionFilter draft;
  final int? deleted;
  final ValueChanged<TransactionFilter> onChanged;
  final VoidCallback onOpenDeleted;

  Future<void> _pickPeriod(BuildContext context, PeriodPreset period) async {
    if (period != PeriodPreset.custom) {
      onChanged(draft.copyWith(period: period, custom: null));
      return;
    }
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 366)),
    );
    if (range == null) return;
    String d(DateTime v) =>
        '${v.year.toString().padLeft(4, '0')}-${v.month.toString().padLeft(2, '0')}-${v.day.toString().padLeft(2, '0')}';
    onChanged(
      draft.copyWith(
        period: period,
        custom: DateRange(d(range.start), d(range.end)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    String names(Set<String> ids, Map<String, String> byId) => ids.isEmpty
        ? s.txFilterAny
        : ids.map((id) => byId[id] ?? '').join(', ');
    final categories = {for (final c in model.categories) c.id: c.name};
    final tags = {for (final t in model.tags) t.id: t.name};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilterChipsSection(
          model: model,
          draft: draft,
          onChanged: onChanged,
          onPickPeriod: (p) => _pickPeriod(context, p),
        ),
        const SizedBox(height: 20),
        FilterSelectField(
          label: s.txFilterCategories,
          value: names(draft.categoryIds, categories),
          onTap: () async {
            final picked = await showFilterPickSheet(
              context,
              title: s.txFilterCategories,
              selected: draft.categoryIds,
              options: [
                for (final parent in model.categories.where(
                  (c) => c.parentId == null && !c.archived,
                )) ...[
                  PickOption(parent.id, parent.name),
                  for (final child in model.categories.where(
                    (c) => c.parentId == parent.id && !c.archived,
                  ))
                    PickOption(child.id, child.name, indent: true),
                ],
              ],
            );
            if (picked != null) onChanged(draft.copyWith(categoryIds: picked));
          },
        ),
        const SizedBox(height: 8),
        FilterSelectField(
          label: s.txFilterTags,
          value: names(draft.tagIds, tags),
          onTap: () async {
            final picked = await showFilterPickSheet(
              context,
              title: s.txFilterTags,
              selected: draft.tagIds,
              options: [
                for (final tag in model.tags) PickOption(tag.id, tag.name),
              ],
            );
            if (picked != null) onChanged(draft.copyWith(tagIds: picked));
          },
        ),
        const SizedBox(height: 20),
        InkWell(
          onTap: onOpenDeleted,
          child: SizedBox(
            height: FreevaSize.touch,
            child: Row(
              children: [
                Icon(LucideIcons.trash, size: 18, color: c.textOnWash),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s.txFilterDeleted,
                    style: FreevaTypography.body.copyWith(
                      fontWeight: FontWeight.w500,
                      color: c.textOnWash,
                    ),
                  ),
                ),
                if (deleted != null) ...[
                  Text(
                    '$deleted',
                    style: FreevaTypography.bodyS.copyWith(
                      color: c.textSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Icon(
                  LucideIcons.chevronRight,
                  size: FreevaSize.iconChip,
                  color: c.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
