import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_icon_button.dart';
import '../../../../core/widgets/freeva_segmented.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../domain/report.dart';
import '../viewmodels/report_view_model.dart';
import 'report_period_labels.dart';
import 'report_range_fields.dart';

/// Tuần · Tháng · Năm · Tuỳ chọn, then "‹ Tháng 10, 2026 ›" with the date span.
/// The next button locks once the period reaches today.
class ReportPeriodNav extends StatelessWidget {
  const ReportPeriodNav({required this.model, super.key});

  final ReportViewModel model;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final kinds = {
      ReportPeriodKind.week: s.reportWeek,
      ReportPeriodKind.month: s.reportMonth,
      ReportPeriodKind.year: s.reportYear,
      ReportPeriodKind.range: s.reportRange,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FreevaSegmented<ReportPeriodKind>(
          expand: true,
          selected: model.kind,
          onChanged: model.busy ? (_) {} : model.select,
          segments: [
            for (final e in kinds.entries) FreevaSegment(e.key, e.value),
          ],
        ),
        const SizedBox(height: FreevaSpace.s4),
        if (model.kind == ReportPeriodKind.range)
          ReportRangeFields(model: model)
        else
          _Stepper(model: model),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.model});

  final ReportViewModel model;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final period = model.data?.report.period;
    final title = period == null
        ? null
        : periodTitle(s, period, Localizations.localeOf(context).toString());
    return Row(
      children: [
        FreevaIconButton(
          icon: LucideIcons.chevronLeft,
          label: s.reportPrevious,
          onPressed: model.canStep ? () => model.step(-1) : null,
        ),
        Expanded(
          child: title == null
              ? const Center(child: SkeletonBox(width: 120, height: 36))
              : Semantics(
                  liveRegion: true,
                  child: Column(
                    children: [
                      Text(
                        title.title,
                        textAlign: TextAlign.center,
                        style: FreevaTypography.titleL.copyWith(
                          color: c.textPrimary,
                        ),
                      ),
                      if (title.subtitle != null)
                        Text(
                          title.subtitle!,
                          style: FreevaTypography.label.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
        ),
        FreevaIconButton(
          icon: LucideIcons.chevronRight,
          label: s.reportNext,
          onPressed: model.canStepNext ? () => model.step(1) : null,
        ),
      ],
    );
  }
}
