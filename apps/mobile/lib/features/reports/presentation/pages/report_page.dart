import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../domain/report.dart';
import '../viewmodels/report_view_model.dart';
import '../widgets/report_body.dart';

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
    builder: (context, _) {
      final s = S.of(context);
      return Scaffold(
        appBar: AppBar(
          title: Text(s.reportTitle),
          leading: IconButton(
            tooltip: s.profileBack,
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/home'),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (model.busy) const LinearProgressIndicator(),
              Expanded(child: ReportBody(model: model)),
            ],
          ),
        ),
      );
    },
  );
}
