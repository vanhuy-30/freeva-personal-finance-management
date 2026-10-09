import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../wallets/domain/wallet.dart';
import '../../domain/report.dart';
import 'report_amount.dart';

class ReportAccountTile extends StatelessWidget {
  const ReportAccountTile({
    required this.row,
    required this.currencies,
    super.key,
  });

  final CashflowAccountRow row;
  final List<WalletCurrency> currencies;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Card(
      key: ValueKey('account-${row.accountId}'),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(row.name ?? ''),
            ReportAmountText(
              label: s.reportIncome,
              minor: row.incomeMinor,
              currency: row.currency,
              currencies: currencies,
              tone: ReportTone.income,
            ),
            ReportAmountText(
              label: s.reportExpense,
              minor: row.expenseMinor,
              currency: row.currency,
              currencies: currencies,
              tone: ReportTone.expense,
            ),
            ReportAmountText(
              label: s.reportTransfer,
              minor: row.transferMinor,
              currency: row.currency,
              currencies: currencies,
            ),
            ReportAmountText(
              label: s.reportNet,
              minor: row.netMinor,
              currency: row.currency,
              currencies: currencies,
            ),
          ],
        ),
      ),
    );
  }
}
