import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/money/currency_catalog.dart';
import '../viewmodels/insights_view_model.dart';
import 'overview_insight_card.dart';

/// Where S.1 sits on Tổng quan: the card with [top] space above it and
/// [bottom] under it, or nothing while there is no insight (flag off, empty,
/// failed or not loaded yet).
class OverviewInsightSlot extends StatelessWidget {
  const OverviewInsightSlot({
    required this.top,
    required this.bottom,
    super.key,
  });

  final double top;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    // Not registered in some widget tests.
    if (!getIt.isRegistered<InsightsViewModel>()) return const SizedBox();
    final model = getIt<InsightsViewModel>();
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        final item = model.first;
        if (item == null) return const SizedBox();
        return Padding(
          padding: EdgeInsets.only(top: top, bottom: bottom),
          child: OverviewInsightCard(
            item: item,
            count: model.items.length,
            digits: CurrencyCatalog.current.digits(model.currencyCode),
            onTap: () => context.push('/insights'),
          ),
        );
      },
    );
  }
}
