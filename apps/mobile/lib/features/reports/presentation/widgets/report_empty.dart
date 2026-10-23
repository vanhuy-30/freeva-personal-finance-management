import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
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
    final label = periodTitle(
      s,
      period,
      Localizations.localeOf(context).toString(),
    ).title.toLowerCase();
    final back = !model.atCurrent && period.kind != ReportPeriodKind.range;
    return Center(
      child: EmptyState(
        title: s.reportEmptyTitle(label),
        message: back ? null : s.reportEmptyHint,
        actionLabel: back ? backLabel(s, period.kind) : null,
        onAction: back ? model.backToCurrent : null,
      ),
    );
  }
}
