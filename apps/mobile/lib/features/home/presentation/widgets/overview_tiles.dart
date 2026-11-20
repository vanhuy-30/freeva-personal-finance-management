import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../goals/domain/goal.dart';
import '../../../goals/presentation/viewmodels/goal_view_model.dart';
import '../../domain/overview.dart';
import '../../domain/overview_glance.dart';
import '../../domain/overview_summary.dart';
import 'card_tile.dart';
import 'goals_tile.dart';
import 'invest_tile.dart';
import 'month_tile.dart';
import 'upcoming_tile.dart';

/// PA 3 grid: the wide month tile, then "Sắp phải trả", "Thẻ tín dụng",
/// "Mục tiêu" and "Đầu tư" two per row. A tile without data is left out;
/// an odd last tile takes the full row.
class OverviewTiles extends StatefulWidget {
  const OverviewTiles({required this.data, required this.currency, super.key});

  /// Space between tiles.
  static const double gap = 12;

  final OverviewData data;

  /// Main currency of the net worth card.
  final String currency;

  @override
  State<OverviewTiles> createState() => _OverviewTilesState();
}

class _OverviewTilesState extends State<OverviewTiles> {
  /// Not registered in some widget tests.
  final GoalViewModel? _goals = getIt.isRegistered<GoalViewModel>()
      ? getIt<GoalViewModel>()
      : null;

  @override
  void initState() {
    super.initState();
    final goals = _goals;
    if (goals != null && !goals.loaded) Future.microtask(goals.load);
  }

  @override
  Widget build(BuildContext context) {
    final goals = _goals;
    if (goals == null) return _grid(context, const []);
    return ListenableBuilder(
      listenable: goals,
      builder: (context, _) => _grid(context, goals.active),
    );
  }

  Widget _grid(BuildContext context, List<Goal> goals) {
    final data = widget.data;
    final main = widget.currency;
    final digits = data.digitsOf(main);
    final today = data.loadedAt;
    final from = DateTime.parse(data.month.period.from);
    final to = DateTime.parse(data.month.period.to);
    final cards = [
      for (final card in creditCards(data.wallets, today))
        if (card.wallet.draft.currency == main) card,
    ];
    final calendar = data.calendar;
    final loans = data.loans;
    final upcoming = calendar == null || loans == null
        ? null
        : upcomingSummary(
            today: today,
            until: to,
            currency: main,
            calendar: calendar,
            loans: loans,
            cards: cards,
          );
    final invest = investmentGlance(data.investments, data.netWorthTrend, main);
    final budget = data.budget;
    final small = <Widget>[
      if (upcoming != null)
        UpcomingTile(summary: upcoming, today: today, digits: digits),
      if (cards.isNotEmpty) CardTile(cards: cards),
      if (goals.isNotEmpty) GoalsTile(goals: goals),
      if (invest != null) InvestTile(glance: invest, digits: digits),
    ];
    const gap = SizedBox(height: OverviewTiles.gap, width: OverviewTiles.gap);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MonthTile(
          monthLabel: DateFormat(
            S.of(context).homeMonthPattern,
            Localizations.localeOf(context).toString(),
          ).format(from),
          spentMinor: monthFlow(data.month, main).expense,
          digits: digits,
          today: today,
          periodFrom: from,
          periodTo: to,
          budget: budget != null && budget.currencyCode == main ? budget : null,
        ),
        for (var i = 0; i < small.length; i += 2) ...[
          gap,
          if (i + 1 < small.length)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: small[i]),
                  gap,
                  Expanded(child: small[i + 1]),
                ],
              ),
            )
          else
            small[i],
        ],
      ],
    );
  }
}
