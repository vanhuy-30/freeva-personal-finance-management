import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../debts/presentation/widgets/debt_parts.dart';
import '../viewmodels/loan_view_model.dart';
import '../widgets/loan_schedule_row.dart';

/// "Xem cả lịch": every period left, same rows as the detail.
class LoanSchedulePage extends StatefulWidget {
  const LoanSchedulePage({required this.loanId, super.key});

  final String loanId;

  @override
  State<LoanSchedulePage> createState() => _LoanSchedulePageState();
}

class _LoanSchedulePageState extends State<LoanSchedulePage> {
  late final LoanViewModel model = getIt<LoanViewModel>();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (!model.loaded) await model.load();
      final loan = model.byId(widget.loanId);
      if (loan != null && model.scheduleOf(loan.id) == null) {
        await model.loadSchedule(loan);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        final loan = model.byId(widget.loanId);
        final rows = loan == null ? null : model.scheduleOf(loan.id);
        return Scaffold(
          appBar: FreevaTopBar(
            title: s.loanSchedule,
            subtitle: loan?.name,
            onLeading: () =>
                context.popOrGo('/me/debts/loans/${widget.loanId}'),
          ),
          body: rows == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: EdgeInsets.fromLTRB(
                    context.screenMargin,
                    FreevaSpace.s2,
                    context.screenMargin,
                    28,
                  ),
                  children: [
                    DebtCard(
                      children: [
                        for (final row in rows)
                          LoanScheduleRowTile(
                            row: row,
                            digits: model.digitsOf(loan!.currencyCode),
                            next: row.index == 1,
                          ),
                      ],
                    ),
                  ],
                ),
        );
      },
    );
  }
}
