import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../domain/report.dart';
import '../viewmodels/report_view_model.dart';
import 'report_range_fields.dart';

class ReportPeriodBar extends StatelessWidget {
  const ReportPeriodBar({required this.model, super.key});

  final ReportViewModel model;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final period = model.data?.report.period;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final kind in ReportPeriodKind.values)
                ChoiceChip(
                  label: Text(_label(s, kind)),
                  selected: model.kind == kind,
                  onSelected: model.busy ? null : (_) => model.select(kind),
                ),
            ],
          ),
          if (model.kind == ReportPeriodKind.range)
            ReportRangeFields(model: model)
          else
            Row(
              children: [
                IconButton(
                  tooltip: s.reportPrevious,
                  onPressed: model.canStep ? () => model.step(-1) : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    period == null
                        ? ''
                        : s.reportPeriod(period.from, period.to),
                  ),
                ),
                IconButton(
                  tooltip: s.reportNext,
                  onPressed: model.canStep ? () => model.step(1) : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

String _label(S s, ReportPeriodKind kind) => switch (kind) {
  ReportPeriodKind.week => s.reportWeek,
  ReportPeriodKind.month => s.reportMonth,
  ReportPeriodKind.range => s.reportRange,
};
