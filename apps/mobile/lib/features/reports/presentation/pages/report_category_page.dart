import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../../home/presentation/widgets/recent_row_data.dart';
import '../../../transactions/domain/transaction.dart';
import '../../../transactions/domain/transaction_filter.dart';
import '../../../transactions/domain/transaction_repository.dart';
import '../../../transactions/presentation/viewmodels/transaction_view_model.dart';
import '../../../transactions/presentation/widgets/transaction_detail_sheet.dart';
import '../../domain/category_detail.dart';
import '../viewmodels/category_report_view_model.dart';
import '../widgets/category_bars.dart';
import '../widgets/category_header.dart';
import '../widgets/largest_transactions.dart';
import '../widgets/report_period_labels.dart';

/// One slice of the breakdown in the period: total, share, the child
/// categories and the largest transactions. A pushed screen (no bottom nav).
class ReportCategoryPage extends StatefulWidget {
  const ReportCategoryPage({required this.args, super.key});

  final CategoryDetailArgs args;

  @override
  State<ReportCategoryPage> createState() => _ReportCategoryPageState();
}

class _ReportCategoryPageState extends State<ReportCategoryPage> {
  late final CategoryReportViewModel model = CategoryReportViewModel(
    getIt<TransactionRepository>(),
    getIt<AuthViewModel>(),
    widget.args,
  );
  late final TransactionViewModel transactions = getIt<TransactionViewModel>();

  @override
  void initState() {
    super.initState();
    if (!transactions.composerReady) Future.microtask(transactions.load);
    Future.microtask(model.load);
  }

  @override
  void dispose() {
    model.dispose();
    super.dispose();
  }

  void _seeAll() {
    final args = widget.args;
    transactions.setFilter(
      TransactionFilter(
        type: model.type,
        period: PeriodPreset.custom,
        custom: DateRange(args.report.period.from, args.report.period.to),
        categoryIds: {...?args.categoryIds},
      ),
    );
    context.go('/transactions');
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final args = widget.args;
    final detail = categoryDetail(args);
    final margin = context.screenMargin;
    const gap = SizedBox(height: FreevaSpace.s4);
    return ListenableBuilder(
      listenable: Listenable.merge([model, transactions]),
      builder: (context, _) {
        final single = args.slice.memberIds.length == 1 ? args.slice.id : null;
        final icon = transactions.categories
            .where((category) => category.id == single)
            .map((category) => category.iconToken)
            .firstOrNull;
        return Scaffold(
          appBar: FreevaTopBar(
            title: args.slice.name ?? s.reportOther,
            subtitle: periodTitle(
              s,
              args.report.period,
              Localizations.localeOf(context).toString(),
            ).title,
            onLeading: () => context.popOrGo('/reports'),
          ),
          body: ListView(
            padding: EdgeInsets.fromLTRB(
              margin,
              FreevaSpace.s2,
              margin,
              FreevaSpace.s8,
            ),
            children: [
              CategoryHeader(
                args: args,
                detail: detail,
                count: model.count,
                iconToken: icon,
              ),
              gap,
              CategoryBars(
                detail: detail,
                currency: args.currency,
                digits: args.digits,
              ),
              if (model.available) ...[
                gap,
                LargestTransactions(
                  model: model,
                  names: RecentRowNames(
                    s,
                    transactions.categories,
                    transactions.wallets,
                  ),
                  digitsOf: (_) => args.digits,
                  onOpen: (TransactionBundle row) =>
                      openTransactionDetail(context, transactions, row),
                  onSeeAll: _seeAll,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
