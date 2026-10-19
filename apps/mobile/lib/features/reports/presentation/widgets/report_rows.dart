import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../wallets/domain/wallet.dart';
import '../../domain/report.dart';
import 'report_amount.dart';

class ReportCategoryTile extends StatelessWidget {
  const ReportCategoryTile({
    required this.row,
    required this.currencies,
    super.key,
  });

  final CashflowCategoryRow row;
  final List<WalletCurrency> currencies;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final title = row.categoryId == null
        ? s.reportUncategorized
        : (row.name ?? '');
    return Card(
      key: ValueKey('category-${row.categoryId ?? 'none'}-${row.currency}'),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            if (row.parentName != null)
              Text(
                row.parentName!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
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
          ],
        ),
      ),
    );
  }
}
