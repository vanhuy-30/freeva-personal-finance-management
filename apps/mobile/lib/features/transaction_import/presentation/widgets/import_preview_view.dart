import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/freeva_chip.dart';
import '../../../../core/widgets/freeva_switch.dart';
import '../../domain/import_models.dart';
import '../viewmodels/import_view_model.dart';
import 'import_preview_row.dart';

/// Board `ImportPreview`: what would be written, row by row. With category
/// suggestions (board R.2) a "Gợi ý N" chip filters the guessed rows.
class ImportPreviewView extends StatelessWidget {
  const ImportPreviewView({
    required this.model,
    required this.onCommit,
    required this.onPickCategory,
    super.key,
  });
  final ImportViewModel model;
  final VoidCallback onCommit;

  /// Opens "Đổi danh mục" (board R.3) for a row.
  final ValueChanged<ImportRow> onPickCategory;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final summary = model.preview?.summary;
    final rows = model.shownRows;
    final count = model.importCount;
    final suggesting = model.filter == ImportFilter.suggested;
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
                      if (model.suggestedCount > 0)
                        (
                          ImportFilter.suggested,
                          s.importFilterSuggested(model.suggestedCount),
                        ),
                      (ImportFilter.duplicate, s.importDuplicate),
                      (ImportFilter.invalid, s.importInvalid),
                    ])
                      FreevaChip(
                        label: label,
                        icon: filter == ImportFilter.suggested
                            ? LucideIcons.sparkles
                            : null,
                        iconSize: FreevaSize.iconXs,
                        selected: model.filter == filter,
                        onTap: () => model.selectFilter(filter),
                      ),
                  ],
                ),
              ),
              if (suggesting) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 14)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(left: FreevaSpace.s1),
                    child: Text(
                      s.importSuggestHint,
                      style: FreevaTypography.bodyS.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
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
                    itemBuilder: (context, i) => ImportPreviewRow(
                      row: rows[i],
                      model: model,
                      divider: i > 0,
                      onTap: model.canPickCategory(rows[i])
                          ? () => onPickCategory(rows[i])
                          : null,
                    ),
                  ),
                ),
              // Board R.2 leaves the duplicates switch out of the guessed
              // rows; it comes back with the other filters.
              if (!suggesting) ...[
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
              ],
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
