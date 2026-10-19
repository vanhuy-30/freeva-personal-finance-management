import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../domain/report.dart';
import '../viewmodels/report_view_model.dart';
import 'report_account_tile.dart';
import 'report_labels.dart';
import 'report_period_bar.dart';
import 'report_rows.dart';
import 'report_totals.dart';

class ReportBody extends StatelessWidget {
  const ReportBody({required this.model, super.key});

  final ReportViewModel model;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final data = model.data;
    final report = data?.report;
    final empty =
        report != null &&
        report.totals.isEmpty &&
        report.byCategory.isEmpty &&
        report.byAccount.isEmpty;
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        ReportPeriodBar(model: model),
        if (model.failure != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Semantics(
              liveRegion: true,
              child: Text(
                reportFailure(s, model.failure!),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: model.busy ? null : model.reload,
            child: Text(s.profileReload),
          ),
        ),
        if (data == null &&
            !model.busy &&
            model.failure == null &&
            model.kind != ReportPeriodKind.range)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(s.reportEmpty),
          ),
        if (report != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final total in report.totals)
                  ReportTotalCard(total: total, currencies: data!.currencies),
                if (empty) Text(s.reportEmpty),
                Text(
                  s.reportByCategory,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                for (final row in report.byCategory)
                  ReportCategoryTile(row: row, currencies: data!.currencies),
                Text(
                  s.reportByAccount,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                for (final row in report.byAccount)
                  ReportAccountTile(row: row, currencies: data!.currencies),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
