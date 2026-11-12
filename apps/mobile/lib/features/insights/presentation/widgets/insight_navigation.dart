import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../transactions/domain/transaction.dart';
import '../../../transactions/domain/transaction_filter.dart';
import '../../../transactions/presentation/viewmodels/transaction_view_model.dart';
import '../../../transactions/presentation/widgets/transaction_detail_sheet.dart';
import '../../domain/insight.dart';

/// Where tapping an insight on Phân tích leads: the month's budget, the
/// unusual transaction, the category's transactions this month, or Báo cáo.
Future<void> openInsight(
  BuildContext context,
  Insight item,
  InsightPeriod? period,
) async {
  switch (item) {
    case BudgetRiskInsight():
      await context.push('/budgets');
    case OutlierInsight(:final transactionId):
      final transactions = getIt<TransactionViewModel>();
      if (!transactions.composerReady) transactions.load();
      final bundle = await transactions.open(transactionId);
      if (bundle == null || !context.mounted) return;
      await openTransactionDetail(context, transactions, bundle);
    case CategoryChangeInsight(:final category):
      getIt<TransactionViewModel>().setFilter(
        TransactionFilter(
          type: TransactionType.expense,
          period: period == null ? PeriodPreset.thisMonth : PeriodPreset.custom,
          custom: period == null ? null : DateRange(period.from, period.today),
          categoryIds: {category.id},
        ),
      );
      context.go('/transactions');
    case SpendTrendInsight():
      context.go('/reports');
  }
}
