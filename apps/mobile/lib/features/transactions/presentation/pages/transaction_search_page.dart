import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../domain/transaction_filter.dart';
import '../viewmodels/transaction_results_view_model.dart';
import '../viewmodels/transaction_view_model.dart';
import '../widgets/period_sheet.dart';
import '../widgets/search_field_bar.dart';
import '../widgets/search_results_body.dart';
import '../widgets/transaction_filter_bar.dart';

/// Tìm kiếm (C1.2): focused field, type chips, "Mọi lúc" period, count and
/// totals, matches marked. Accent-insensitive, updates 300 ms after typing.
class TransactionSearchPage extends StatefulWidget {
  const TransactionSearchPage({super.key});

  @override
  State<TransactionSearchPage> createState() => _TransactionSearchPageState();
}

class _TransactionSearchPageState extends State<TransactionSearchPage> {
  final main = getIt<TransactionViewModel>();
  late final TransactionResultsViewModel results =
      getIt<TransactionResultsViewModel>(param1: false);

  @override
  void dispose() {
    results.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([results, main]),
    builder: (context, _) {
      final margin = context.screenMargin;
      final filter = results.filter;
      return Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  margin,
                  FreevaSpace.s2,
                  margin,
                  FreevaSpace.s3,
                ),
                child: SearchFieldBar(onChanged: results.setSearch),
              ),
              Padding(
                padding: EdgeInsets.only(left: margin, bottom: FreevaSpace.s3),
                child: TransactionFilterBar(
                  filter: filter,
                  range: rangeFor(
                    filter.period,
                    main.today() ?? '2000-01-01',
                    main.fiscalDay,
                    filter.custom,
                  ),
                  names: (_) => '',
                  onChanged: results.setFilter,
                  onOpenSheet: () async {
                    final period = await showPeriodSheet(
                      context,
                      filter.period,
                    );
                    if (period != null) {
                      await results.setFilter(filter.copyWith(period: period));
                    }
                  },
                ),
              ),
              Expanded(
                child: SearchResultsBody(main: main, results: results),
              ),
            ],
          ),
        ),
      );
    },
  );
}
