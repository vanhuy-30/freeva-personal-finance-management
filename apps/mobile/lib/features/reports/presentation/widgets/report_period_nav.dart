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
import '../../domain/report_range.dart';
import 'range_picker_dialog.dart';

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
          onChanged: model.busy
              ? (_) {}
              : (kind) => kind == ReportPeriodKind.range
                    ? _pickRange(context, model)
                    : model.select(kind),
          segments: [
            for (final e in kinds.entries) FreevaSegment(e.key, e.value),
          ],
        ),
        const SizedBox(height: FreevaSpace.s4),
        _Stepper(model: model),
      ],
    );
  }
}

/// Opens the range popup; a picked range loads, cancelling changes nothing.
Future<void> _pickRange(BuildContext context, ReportViewModel model) async {
  final period = model.data?.report.period;
  final current = period?.kind == ReportPeriodKind.range
      ? RangeSelection(from: period!.from, to: period.to)
      : const RangeSelection();
  final picked = await showRangePicker(
    context,
    today: model.today,
    initial: current,
  );
  if (picked != null && picked.complete) {
    await model.applyRange(picked.from!, picked.to!);
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
                  button: model.kind == ReportPeriodKind.range,
                  child: _Tap(
                    onTap: model.kind == ReportPeriodKind.range && !model.busy
                        ? () => _pickRange(context, model)
                        : null,
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

class _Tap extends StatelessWidget {
  const _Tap({required this.onTap, required this.child});

  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: child,
  );
}
