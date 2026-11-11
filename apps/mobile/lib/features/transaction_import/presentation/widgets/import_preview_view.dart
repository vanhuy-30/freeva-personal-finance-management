import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/freeva_chip.dart';
import '../../../../core/widgets/freeva_switch.dart';
import '../../domain/import_models.dart';
import '../viewmodels/import_view_model.dart';
import '../../../../core/money/currency_catalog.dart';

/// Board `ImportPreview`: what would be written, row by row.
class ImportPreviewView extends StatelessWidget {
  const ImportPreviewView({
    required this.model,
    required this.onCommit,
    super.key,
  });
  final ImportViewModel model;
  final VoidCallback onCommit;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final summary = model.preview?.summary;
    final rows = model.shownRows;
    final count = model.importCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: FreevaSpace.s2)),
              SliverToBoxAdapter(
                child: Row(
                  children: [
                    for (final (i, stat) in [
                      (summary?.ready ?? 0, s.importReady, c.statusSuccess),
                      (
                        summary?.duplicate ?? 0,
                        s.importDuplicate,
                        c.statusWarning,
                      ),
                      (summary?.invalid ?? 0, s.importInvalid, c.statusDanger),
                    ].indexed) ...[
                      if (i > 0) const SizedBox(width: FreevaSpace.s2),
                      Expanded(
                        child: _StatCard(
                          value: stat.$1,
                          label: stat.$2,
                          color: stat.$3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
              SliverToBoxAdapter(
                child: Wrap(
                  spacing: FreevaSpace.s2,
                  runSpacing: FreevaSpace.s2,
                  children: [
                    for (final (filter, label) in [
                      (ImportFilter.all, s.importFilterAll),
                      (ImportFilter.duplicate, s.importDuplicate),
                      (ImportFilter.invalid, s.importInvalid),
                    ])
                      FreevaChip(
                        label: label,
                        selected: model.filter == filter,
                        onTap: () => model.selectFilter(filter),
                      ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
              if (rows.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        s.importNoRows,
                        style: FreevaTypography.bodyM.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                  ),
                )
              else
                DecoratedSliver(
                  decoration: BoxDecoration(
                    color: c.listBg,
                    borderRadius: BorderRadius.circular(
                      FreevaComponent.listRadius,
                    ),
                    boxShadow: FreevaElevation.s1,
                  ),
                  sliver: SliverList.builder(
                    itemCount: rows.length,
                    itemBuilder: (context, i) =>
                        _PreviewRow(row: rows[i], model: model, divider: i > 0),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
              SliverToBoxAdapter(
                child: FreevaCard(
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
                              s.importDuplicatesToggle,
                              style: FreevaTypography.body.copyWith(
                                fontWeight: FontWeight.w500,
                                color: c.textPrimary,
                              ),
                            ),
                            Text(
                              s.importDuplicatesHint,
                              style: FreevaTypography.label.copyWith(
                                color: c.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FreevaSwitch(
                        value: model.includeDuplicates,
                        onChanged: model.toggleDuplicates,
                        label: s.importDuplicatesToggle,
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: FreevaSpace.s2)),
            ],
          ),
        ),
        const SizedBox(height: FreevaSpace.s3),
        FreevaButton(
          label: s.importCommit(count),
          size: FreevaButtonSize.l,
          expand: true,
          loading: model.committing,
          onPressed: count > 0 && !model.committing ? onCommit : null,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
  });
  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      label: '$value $label',
      excludeSemantics: true,
      child: FreevaCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: FreevaTypography.titleS.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            Text(
              label,
              style: FreevaTypography.label.copyWith(color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.row,
    required this.model,
    required this.divider,
  });
  final ImportRow row;
  final ImportViewModel model;
  final bool divider;

  String? _tag(S s) {
    if (row.status == ImportRowStatus.duplicate) return s.importTagDuplicate;
    if (row.status != ImportRowStatus.invalid) return null;
    final error = row.errors.firstOrNull ?? ImportRowError.other;
    return switch (error) {
      ImportRowError.dateInvalid => s.importTagDate,
      ImportRowError.amountInvalid => s.importTagAmount,
      ImportRowError.typeUnsupported => s.importTagType,
      ImportRowError.walletUnmapped ||
      ImportRowError.walletAmbiguous => s.importTagWallet,
      ImportRowError.categoryUnmapped ||
      ImportRowError.categoryAmbiguous => s.importTagCategory,
      ImportRowError.categoryKindMismatch => s.importTagCategoryKind,
      ImportRowError.currencyMismatch => s.importTagCurrency,
      ImportRowError.transferUnpaired => s.importTagTransfer,
      ImportRowError.transferSameWallet => s.importTagSameWallet,
      ImportRowError.other => s.importTagOther,
    };
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final tag = _tag(s);
    final duplicate = row.status == ImportRowStatus.duplicate;
    final category = model.categories
        .where((x) => x.id == row.categoryId)
        .firstOrNull
        ?.name;
    final wallet = model.wallets
        .where((w) => w.id == row.accountId)
        .firstOrNull
        ?.draft
        .name;
    final date = row.occurredOn == null
        ? null
        : '${row.occurredOn!.substring(8, 10)}/${row.occurredOn!.substring(5, 7)}';
    final title = row.merchant?.isNotEmpty == true
        ? row.merchant!
        : row.notes?.isNotEmpty == true
        ? row.notes!
        : row.type == 'transfer'
        ? s.transactionTransfer
        : category ?? '';
    final sub = [
      if (date != null) date,
      if (category != null) category,
      if (wallet != null) wallet,
    ].join(' · ');
    String? amount;
    if (row.amountMinor != null) {
      final digits = model.digitsOf(
        row.currencyCode ?? CurrencyCatalog.current.defaultCode,
      );
      final text = formatMoneyText(row.amountMinor!, digits, locale);
      amount = switch (row.type) {
        'expense' => '−$text',
        'income' => '+$text',
        _ => text,
      };
    }
    final muted = duplicate || row.status == ImportRowStatus.invalid;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: divider
            ? Border(top: BorderSide(color: c.borderDivider))
            : null,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 58),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: FreevaTypography.body.copyWith(
                              fontWeight: FontWeight.w500,
                              color: c.textPrimary,
                            ),
                          ),
                        ),
                        if (tag != null) ...[
                          const SizedBox(width: 6),
                          _Tag(label: tag, danger: !duplicate),
                        ],
                      ],
                    ),
                    if (sub.isNotEmpty)
                      Text(
                        sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: FreevaTypography.label.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (amount != null) ...[
                const SizedBox(width: 12),
                Text(
                  amount,
                  maxLines: 1,
                  style: FreevaTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: muted ? c.textSecondary : c.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.danger});
  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: danger ? c.statusDangerBg : c.statusWarningBg,
        borderRadius: BorderRadius.circular(FreevaRadius.full),
      ),
      child: SizedBox(
        height: 24,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              style: FreevaTypography.label.copyWith(
                fontWeight: FontWeight.w500,
                color: danger ? c.statusDanger : c.statusWarning,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
