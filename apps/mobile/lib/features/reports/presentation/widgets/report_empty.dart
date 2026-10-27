import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../domain/report.dart';
import '../viewmodels/report_view_model.dart';
import 'report_period_labels.dart';

/// A period with nothing in it. Past periods offer the way back to the
/// current one; the current one just says what makes numbers appear.
class ReportEmpty extends StatelessWidget {
  const ReportEmpty({required this.model, required this.period, super.key});

  final ReportViewModel model;
  final ReportPeriod period;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final from = DateTime.parse(period.from);
    // "Chưa có số liệu tháng 3": a calendar month drops the year; other
    // periods use their lower-cased title.
    final title = period.kind == ReportPeriodKind.month && from.day == 1
        ? s.reportEmptyTitleMonth('${from.month}')
        : s.reportEmptyTitle(
            periodTitle(
              s,
              period,
              Localizations.localeOf(context).toString(),
            ).title.toLowerCase(),
          );
    final back = !model.atCurrent && period.kind != ReportPeriodKind.range;
    // 72 between the stepper and the illustration beyond the list's 16 gap
    // (the empty state brings 24 of its own).
    return Padding(
      padding: const EdgeInsets.only(top: 72 - FreevaSpace.s6),
      child: Center(
        child: EmptyState(
          title: title,
          message: back ? null : s.reportEmptyHint,
          actionLabel: back ? backLabel(s, period.kind) : null,
          onAction: back ? model.backToCurrent : null,
        ),
      ),
    );
  }
}
