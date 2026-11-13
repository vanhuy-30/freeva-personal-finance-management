import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/check_mark.dart';
import '../../domain/import_models.dart';
import '../viewmodels/import_view_model.dart';
import '../../../server_config/domain/app_limits.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/money/money_text.dart';

/// Board `ImportSource`: where the file comes from.
class ImportSourceView extends StatelessWidget {
  const ImportSourceView({
    required this.model,
    required this.onPick,
    super.key,
  });
  final ImportViewModel model;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    // Server `import.maxRows`, grouped like other numbers ("2.000").
    final maxRows = formatMoneyText(
      BigInt.from(getIt<AppLimitsSource>().requireLimits.importMaxRows),
      0,
      Localizations.localeOf(context).toString(),
    );
    final problem = switch (model.problem) {
      ImportFileProblem.unreadable => s.importProblemUnreadable,
      ImportFileProblem.empty => s.importProblemEmpty,
      ImportFileProblem.tooManyRows => s.importProblemTooMany(maxRows),
      ImportFileProblem.tooLarge => s.importProblemTooLarge,
      null => null,
    };
    final cards = [
      (
        ImportSource.moneyLover,
        s.importSourceMoneyLover,
        s.importSourceMoneyLoverHint,
        LucideIcons.wallet,
        c.tintCyan,
        c.tintCyanFg,
      ),
      (
        ImportSource.misa,
        s.importSourceMisa,
        s.importSourceMisaHint,
        LucideIcons.fileText,
        c.statusWarningBg,
        c.statusWarning,
      ),
      (
        ImportSource.freeva,
        s.importSourceFreeva,
        s.importSourceFreevaHint,
        LucideIcons.filePlus,
        c.tintGreen,
        c.tintGreenFg,
      ),
      (
        ImportSource.other,
        s.importSourceOther,
        s.importSourceOtherHint,
        LucideIcons.file,
        c.bgSubtle,
        c.textPrimary,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(top: FreevaSpace.s1),
            children: [
              Semantics(
                header: true,
                child: Text(
                  s.importSourceHeading,
                  style: FreevaTypography.headlineCompact.copyWith(
                    color: c.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: FreevaSpace.s3),
              for (final (source, label, hint, icon, bg, fg) in cards) ...[
                _SourceCard(
                  label: label,
                  hint: hint,
                  icon: icon,
                  bg: bg,
                  fg: fg,
                  selected: model.source == source,
                  onTap: () => model.selectSource(source),
                ),
                const SizedBox(height: 10),
              ],
              Padding(
                padding: const EdgeInsets.only(left: FreevaSpace.s1),
                child: Text(
                  problem ?? s.importSourceNote(maxRows),
                  style: FreevaTypography.bodyS.copyWith(
                    height: 18 / 13,
                    color: problem == null ? c.textSecondary : c.statusDanger,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: FreevaSpace.s3),
        FreevaButton(
          label: s.importPickFile,
          icon: LucideIcons.upload,
          size: FreevaButtonSize.l,
          expand: true,
          loading: model.busy,
          onPressed: model.busy ? null : onPick,
        ),
      ],
    );
  }
}

/// Source card of the board: 20 radius, 1.5 primary border when chosen, and
/// a round check hanging off the top right corner.
class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.label,
    required this.hint,
    required this.icon,
    required this.bg,
    required this.fg,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String hint;
  final IconData icon;
  final Color bg;
  final Color fg;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(FreevaRadius.lg);
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: '$label, $hint',
      excludeSemantics: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: selected ? c.tintBlue.withValues(alpha: .5) : c.bgSurface,
            shape: RoundedRectangleBorder(
              borderRadius: radius,
              side: BorderSide(
                color: selected ? c.actionPrimary : c.borderDefault,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: InkWell(
              borderRadius: radius,
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(FreevaRadius.sm),
                      ),
                      child: SizedBox.square(
                        dimension: 40,
                        child: Icon(icon, size: 19, color: fg),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: FreevaTypography.body.copyWith(
                              fontWeight: FontWeight.w600,
                              color: c.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hint,
                            style: FreevaTypography.label.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (selected)
            Positioned(
              top: -6,
              right: -6,
              child: ExcludeSemantics(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.actionPrimary,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: c.bgCanvas, spreadRadius: 2)],
                  ),
                  child: SizedBox.square(
                    dimension: 20,
                    child: Center(
                      child: CheckMark(color: c.textOnAction, size: 12),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
