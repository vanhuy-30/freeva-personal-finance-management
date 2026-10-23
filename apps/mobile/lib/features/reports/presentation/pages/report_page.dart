import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../domain/report.dart';
import '../viewmodels/report_view_model.dart';
import '../widgets/report_body.dart';

/// Báo cáo, a tab root (bottom nav stays).
class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  late final ReportViewModel model;

  @override
  void initState() {
    super.initState();
    model = getIt<ReportViewModel>();
    model.beginVisit();
    Future.microtask(() => model.load(const ReportPeriodQuery.month()));
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) => Scaffold(
      appBar: FreevaTopBar(
        title: S.of(context).reportTitle,
        kind: FreevaTopBarKind.largeTitle,
      ),
      body: ReportBody(model: model),
    ),
  );
}
