import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../domain/report.dart';
import 'report_amount.dart';

class OverviewCard extends StatelessWidget {
  const OverviewCard({
    required this.currency,
    required this.snapshot,
    super.key,
  });

  final String currency;
  final OverviewSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final net = snapshot.netWorth.items
        .where((row) => row.currency == currency)
        .firstOrNull;
    final flow = snapshot.month.totals
        .where((row) => row.currency == currency)
        .firstOrNull;
    return Card(
      key: ValueKey('overview-$currency'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(currency, style: Theme.of(context).textTheme.titleMedium),
            if (net != null) ...[
              ReportAmountText(
                label: s.reportAssets,
                minor: net.assetsMinor,
                currency: currency,
                currencies: snapshot.currencies,
              ),
              ReportAmountText(
                label: s.reportLiabilities,
                minor: net.liabilitiesMinor,
                currency: currency,
                currencies: snapshot.currencies,
              ),
              ReportAmountText(
                label: s.reportNetWorth,
                minor: net.netWorthMinor,
                currency: currency,
                currencies: snapshot.currencies,
              ),
            ],
            if (flow != null) ...[
              ReportAmountText(
                label: s.reportIncome,
                minor: flow.incomeMinor,
                currency: currency,
                currencies: snapshot.currencies,
                tone: ReportTone.income,
              ),
              ReportAmountText(
                label: s.reportExpense,
                minor: flow.expenseMinor,
                currency: currency,
                currencies: snapshot.currencies,
                tone: ReportTone.expense,
              ),
              ReportAmountText(
                label: s.reportNet,
                minor: flow.netMinor,
                currency: currency,
                currencies: snapshot.currencies,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
