import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/currency_catalog.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_retry.dart';
import '../../../../core/widgets/freeva_icon_button.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../reports/presentation/widgets/report_labels.dart';
import '../../../spend_forecast/presentation/viewmodels/spend_forecast_view_model.dart';
import '../../../spend_forecast/presentation/widgets/spend_forecast_card.dart';
import '../viewmodels/insights_view_model.dart';
import '../widgets/insight_card.dart';
import '../widgets/insight_navigation.dart';

/// Phân tích (S.2): the month-end forecast card (E06) when there is one,
/// ĐÁNG CHÚ Ý · n with one card per insight, and how the figures are worked
/// out. A forecast failure only hides its card.
class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  late final InsightsViewModel _model = getIt<InsightsViewModel>();
  late final SpendForecastViewModel _forecast = getIt<SpendForecastViewModel>();

  @override
  void initState() {
    super.initState();
    if (!_model.loaded && !_model.loading) Future.microtask(_model.load);
    // Always fresh: the figure moves with every expense.
    if (!_forecast.loading) Future.microtask(_forecast.load);
  }

  Future<void> _refresh() => Future.wait([_model.load(), _forecast.load()]);

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([_model, _forecast]),
    builder: (context, _) {
      final s = S.of(context);
      final margin = context.screenMargin;
      return Scaffold(
        appBar: FreevaTopBar(
          title: s.insightsTitle,
          onLeading: () => context.popOrGo('/home'),
          action: FreevaIconButton(
            icon: LucideIcons.settings,
            iconSize: FreevaSize.iconSm,
            label: s.insightsSettings,
            onPressed: () => context.push('/me/auto-suggest'),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            // Board: 14 between the header row and the first block.
            padding: EdgeInsets.fromLTRB(margin, 6, margin, FreevaSpace.s8),
            children: [..._forecastCard(context), ..._body(context)],
          ),
        ),
      );
    },
  );

  /// The forecast card and the gap under it; nothing when off or failed.
  List<Widget> _forecastCard(BuildContext context) {
    final forecast = _forecast.forecast;
    if (forecast == null) return const [];
    return [
      SpendForecastCard(
        forecast: forecast,
        period: _forecast.period,
        digits: CurrencyCatalog.current.digits(_forecast.currencyCode),
        onTap: () => context.push('/insights/spending-forecast'),
      ),
      // Board: 14 gap plus 6 above the section label.
      const SizedBox(height: 20),
    ];
  }

  List<Widget> _body(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final items = _model.items;
    if (items.isEmpty) {
      final failure = _model.failure;
      if (failure != null && !_model.loading) {
        return [
          ErrorRetry(
            title: reportFailure(s, failure),
            message: s.homeErrorBody,
            onRetry: _model.load,
          ),
        ];
      }
      if (!_model.loaded) {
        return const [
          SkeletonBox(height: 120, radius: FreevaRadius.lg),
          SizedBox(height: 14),
          SkeletonBox(height: 120, radius: FreevaRadius.lg),
        ];
      }
      return [EmptyState(title: s.insightsEmpty, message: s.insightsEmptyBody)];
    }
    final digits = CurrencyCatalog.current.digits(_model.currencyCode);
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: FreevaSpace.s1),
        child: Semantics(
          header: true,
          child: Text(
            s.insightsSection(items.length).toUpperCase(),
            style: FreevaTypography.sectionLabel.copyWith(
              color: c.textSecondary,
            ),
          ),
        ),
      ),
      // Board: 14 column gap under a 14.5 (not 16) line.
      const SizedBox(height: 13),
      for (final (i, item) in items.indexed) ...[
        if (i > 0) const SizedBox(height: 14),
        InsightCard(
          item: item,
          digits: digits,
          onTap: () => openInsight(context, item, _model.period),
        ),
      ],
      const SizedBox(height: 18),
      Text(
        s.insightsFooter,
        textAlign: TextAlign.center,
        style: FreevaTypography.bodyS.copyWith(color: c.textSecondary),
      ),
    ];
  }
}
