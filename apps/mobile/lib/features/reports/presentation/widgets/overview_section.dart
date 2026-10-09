import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../domain/report.dart';
import '../viewmodels/overview_view_model.dart';
import 'overview_card.dart';
import 'report_labels.dart';

class OverviewSection extends StatefulWidget {
  const OverviewSection({super.key});

  @override
  State<OverviewSection> createState() => _OverviewSectionState();
}

class _OverviewSectionState extends State<OverviewSection> {
  late final OverviewViewModel model;

  @override
  void initState() {
    super.initState();
    model = getIt<OverviewViewModel>();
    Future.microtask(model.load);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) {
      final s = S.of(context);
      final snapshot = model.snapshot;
      final codes = snapshot == null ? const <String>[] : _currencies(snapshot);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.reportOverview, style: Theme.of(context).textTheme.titleLarge),
          if (model.busy) const LinearProgressIndicator(),
          if (model.failure != null)
            Text(
              reportFailure(s, model.failure!),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          if (snapshot != null) ...[
            Text(s.reportThisMonth),
            Text(
              s.reportPeriod(
                snapshot.month.period.from,
                snapshot.month.period.to,
              ),
            ),
            for (final code in codes)
              OverviewCard(currency: code, snapshot: snapshot),
          ],
          if (snapshot != null && codes.isEmpty && !model.busy)
            Text(s.reportEmpty),
          if (!model.busy)
            OutlinedButton(onPressed: model.load, child: Text(s.profileReload)),
        ],
      );
    },
  );
}

List<String> _currencies(OverviewSnapshot snapshot) => {
  ...snapshot.netWorth.items.map((row) => row.currency),
  ...snapshot.month.totals.map((row) => row.currency),
}.toList();
