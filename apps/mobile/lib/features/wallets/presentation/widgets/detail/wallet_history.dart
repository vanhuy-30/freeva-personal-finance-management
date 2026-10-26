import 'package:flutter/material.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../core/widgets/error_retry.dart';
import '../../../../../core/widgets/skeleton.dart';
import '../../../../transactions/presentation/viewmodels/transaction_results_view_model.dart';
import '../../../../transactions/presentation/viewmodels/transaction_view_model.dart';
import '../../../../transactions/presentation/widgets/transaction_day_list.dart';
import '../../../../transactions/presentation/widgets/transaction_detail_sheet.dart';
import '../../../../transactions/presentation/widgets/transaction_naming.dart';

/// This wallet's transactions by day, newest first. Rows leave out the
/// wallet's own name. Tapping opens the usual transaction sheet; [onChanged]
/// runs after it closes.
class WalletHistory extends StatelessWidget {
  const WalletHistory({
    required this.walletId,
    required this.credit,
    required this.main,
    required this.results,
    required this.onChanged,
    super.key,
  });

  final String walletId;
  final bool credit;
  final TransactionViewModel main;
  final TransactionResultsViewModel results;
  final Future<void> Function() onChanged;

  int _digits(String code) =>
      main.currencies
          .where((c) => c.code == code)
          .map((c) => c.minorDigits)
          .firstOrNull ??
      0;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final rows = results.rows;
    if (rows.isEmpty && results.failure != null && !results.loading) {
      return ErrorRetry(
        title: s.transactionError,
        message: s.homeErrorBody,
        onRetry: results.reload,
      );
    }
    if (rows.isEmpty && (results.loading || !main.composerReady)) {
      return const SkeletonRows();
    }
    if (rows.isEmpty) {
      return EmptyState(
        title: s.walletNoTransactions,
        message: credit
            ? s.creditNoTransactionsBody
            : s.walletNoTransactionsBody,
      );
    }
    return TransactionDayList(
      rows: rows,
      naming: TransactionNaming(
        s,
        categories: main.categories,
        wallets: [
          for (final w in main.wallets)
            if (w.id != walletId) w,
        ],
        tags: main.tags,
      ),
      digitsOf: _digits,
      mainCurrency: main.profileCurrency,
      today: main.today() ?? '',
      onOpen: (row) async {
        await openTransactionDetail(context, main, row);
        await onChanged();
      },
    );
  }
}
