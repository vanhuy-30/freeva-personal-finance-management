import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/currency_catalog.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_retry.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../reports/presentation/widgets/report_labels.dart';
import '../../domain/spending_forecast.dart';
import '../viewmodels/spend_forecast_view_model.dart';
import '../widgets/spend_forecast_labels.dart';
import '../widgets/spend_forecast_parts.dart';
import '../widgets/spend_forecast_summary.dart';

/// Dự báo chi (S.3): the month-end total with its chart, the daily average,
/// what each day may still take, the top three categories and how the
/// figure is worked out.
class SpendForecastPage extends StatefulWidget {
  const SpendForecastPage({super.key});

  @override
  State<SpendForecastPage> createState() => _SpendForecastPageState();
}

class _SpendForecastPageState extends State<SpendForecastPage> {
  late final SpendForecastViewModel _model = getIt<SpendForecastViewModel>();

  @override
  void initState() {
    super.initState();
    if (!_model.loaded && !_model.loading) Future.microtask(_model.load);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _model,
    builder: (context, _) {
      final s = S.of(context);
      final margin = context.screenMargin;
      return Scaffold(
        appBar: FreevaTopBar(
          title: s.spendForecastTitle,
          onLeading: () => context.popOrGo('/insights'),
        ),
        body: RefreshIndicator(
          onRefresh: _model.load,
          child: ListView(
            // Board: 14 between the header row and the first block.
            padding: EdgeInsets.fromLTRB(margin, 6, margin, FreevaSpace.s8),
            children: _body(context),
          ),
        ),
      );
    },
  );

  List<Widget> _body(BuildContext context) {
    final s = S.of(context);
    final forecast = _model.forecast;
    if (forecast == null) {
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
        return const [SkeletonBox(height: 320, radius: FreevaRadius.xl)];
      }
    }
    if (forecast == null || !forecast.ready) {
      return [
        EmptyState(
          title: s.spendForecastEmpty,
          message: s.spendForecastEmptyBody,
        ),
      ];
    }
    return _content(context, forecast);
  }

  List<Widget> _content(BuildContext context, SpendingForecast forecast) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final digits = CurrencyCatalog.current.digits(_model.currencyCode);
    String money(BigInt v) => formatMoneyText(v, digits, locale);
    final side = forecastSideTile(s, forecast, money);
    return [
      SpendForecastSummary(
        forecast: forecast,
        period: _model.period,
        digits: digits,
      ),
      const SizedBox(height: 14),
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ForecastMiniTile(
                label: s.spendForecastDailyAverage,
                value: money(forecast.dailyAverageMinor),
              ),
            ),
            const SizedBox(width: FreevaSpace.s2),
            Expanded(
              child: ForecastMiniTile(
                label: side.$1,
                value: side.$2,
                tone: side.$3,
              ),
            ),
          ],
        ),
      ),
      if (forecast.topCategories.isNotEmpty) ...[
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: FreevaSpace.s1),
          child: Semantics(
            header: true,
            child: Text(
              s.spendForecastTop.toUpperCase(),
              style: FreevaTypography.sectionLabel.copyWith(
                color: c.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        SpendTopCategories(items: forecast.topCategories, digits: digits),
      ],
      const SizedBox(height: 14),
      const SpendForecastNote(),
    ];
  }
}
