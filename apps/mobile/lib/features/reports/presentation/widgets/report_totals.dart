import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../wallets/domain/wallet.dart';
import '../../domain/report.dart';
import 'report_amount.dart';

class ReportTotalCard extends StatelessWidget {
  const ReportTotalCard({
    required this.total,
    required this.currencies,
    super.key,
  });

  final CashflowTotal total;
  final List<WalletCurrency> currencies;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Card(
      key: ValueKey('total-${total.currency}'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              total.currency,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            ReportAmountText(
              label: s.reportIncome,
              minor: total.incomeMinor,
              currency: total.currency,
              currencies: currencies,
              tone: ReportTone.income,
            ),
            ReportAmountText(
              label: s.reportExpense,
              minor: total.expenseMinor,
              currency: total.currency,
              currencies: currencies,
              tone: ReportTone.expense,
            ),
            ReportAmountText(
              label: s.reportNet,
              minor: total.netMinor,
              currency: total.currency,
              currencies: currencies,
            ),
          ],
        ),
      ),
    );
  }
}
