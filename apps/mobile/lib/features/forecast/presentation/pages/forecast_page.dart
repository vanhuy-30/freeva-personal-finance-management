import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/error_retry.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/freeva_segmented.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../../core/widgets/money_display.dart';
import '../../../../core/widgets/settings_group.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../../categories/presentation/viewmodels/category_view_model.dart';
import '../../../profile/presentation/viewmodels/profile_view_model.dart';
import '../../../recurring/domain/recurring_use_cases.dart';
import '../../../reports/presentation/widgets/report_labels.dart';
import '../../../settings/presentation/widgets/balances_hidden_builder.dart';
import '../../../wallets/presentation/viewmodels/wallet_view_model.dart';
import '../../domain/forecast_use_cases.dart';
import '../viewmodels/forecast_view_model.dart';
import '../widgets/forecast_balance_sheet.dart';
import '../widgets/forecast_chart.dart';
import '../widgets/forecast_how_card.dart';
import '../widgets/forecast_labels.dart';
import '../widgets/forecast_rule_row.dart';

/// Pushed from Reports: where the balance is heading, counting only the
/// recurring items and bills the user already has.
class ForecastPage extends StatefulWidget {
  const ForecastPage({super.key});

  @override
  State<ForecastPage> createState() => _ForecastPageState();
}

class _ForecastPageState extends State<ForecastPage> {
  late final ForecastViewModel model = ForecastViewModel(
    getIt<ForecastUseCases>(),
    getIt<RecurringUseCases>(),
    getIt<AuthViewModel>(),
    getIt<ProfileViewModel>(),
    getIt<WalletViewModel>(),
  );
  late final CategoryViewModel categories = getIt<CategoryViewModel>();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      model.load();
      categories.load();
    });
  }

  @override
  void dispose() {
    model.dispose();
    super.dispose();
  }

  Future<void> _editBalance() async {
    final data = model.data;
    if (data == null) return;
    final choice = await showForecastBalanceSheet(
      context,
      current: data.startingBalanceMinor,
      currency: model.currency,
      digits: model.digits,
      custom: model.startingOverride != null,
    );
    if (choice == null) return;
    await model.setStarting(choice.reset ? null : choice.minor);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final margin = context.screenMargin;
    return BalancesHiddenBuilder(
      builder: (context, hidden) => ListenableBuilder(
        listenable: Listenable.merge([model, categories]),
        builder: (context, _) => Scaffold(
          appBar: FreevaTopBar(
            title: s.forecastTitle,
            onLeading: () => context.popOrGo('/reports'),
          ),
          body: RefreshIndicator(
            onRefresh: model.reload,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                margin,
                FreevaSpace.s2,
                margin,
                FreevaSpace.s8,
              ),
              children: [
                FreevaSegmented<int>(
                  expand: true,
                  segments: [
                    for (final months in ForecastViewModel.ranges)
                      FreevaSegment(months, s.forecastRange(months)),
                  ],
                  selected: model.months,
                  onChanged: model.selectMonths,
                ),
                const SizedBox(height: FreevaSpace.s4),
                ..._body(context, hidden),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _body(BuildContext context, bool hidden) {
    final s = S.of(context);
    const gap = SizedBox(height: FreevaSpace.s4);
    final data = model.data;
    if (data == null) {
      if (model.failure != null && !model.busy) {
        return [
          ErrorRetry(
            title: reportFailure(s, model.failure!),
            message: s.homeErrorBody,
            onRetry: model.reload,
          ),
        ];
      }
      return const [
        SkeletonBox(height: 300, radius: 24),
        gap,
        SkeletonBox(height: 150, radius: 24),
      ];
    }
    return [
      AnimatedOpacity(
        opacity: model.busy ? 0.6 : 1,
        duration: FreevaMotion.fast,
        child: _SummaryCard(model: model, hidden: hidden),
      ),
      if (model.failure != null) ...[
        const SizedBox(height: FreevaSpace.s2),
        Text(
          reportFailure(s, model.failure!),
          style: FreevaTypography.bodyS.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
      ],
      gap,
      ForecastHowCard(model: model, hidden: hidden, onEdit: _editBalance),
      SectionHeader(s.forecastRulesHeader),
      _Rules(model: model, categories: categories),
    ];
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.model, required this.hidden});

  final ForecastViewModel model;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final data = model.data!;
    final last = data.months.isEmpty ? null : data.months.last.month;
    final change = data.changeMinor;
    final changeText = hidden
        ? '••••••'
        : signedMoney(change, model.digits, locale);
    return FreevaCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (last != null)
            Text(
              s.forecastEndOfMonth(forecastMonthNumber(last)),
              style: FreevaTypography.label.copyWith(
                fontWeight: FontWeight.w400,
                color: c.textSecondary,
              ),
            ),
          const SizedBox(height: 4),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: MoneyDisplay(
              minor: data.endingMinor,
              currency: model.currency,
              minorDigits: model.digits,
              style: FreevaTypography.moneyDisplayCompact.copyWith(
                letterSpacing: -0.9,
              ),
              hidden: hidden,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            s.forecastChange(changeText),
            style: FreevaTypography.bodyS.copyWith(
              color: change.isNegative ? c.textSecondary : c.moneyIncome,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 20),
          ForecastChart(forecast: data, digits: model.digits, hidden: hidden),
        ],
      ),
    );
  }
}

class _Rules extends StatelessWidget {
  const _Rules({required this.model, required this.categories});

  final ForecastViewModel model;
  final CategoryViewModel categories;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final rows = model.rows;
    if (rows.isEmpty) {
      return FreevaCard(
        padding: const EdgeInsets.all(18),
        child: Text(
          s.forecastNoRules,
          style: FreevaTypography.bodyM.copyWith(color: c.textSecondary),
        ),
      );
    }
    return FreevaCard(
      list: true,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, color: c.borderDivider),
            ForecastRuleRow(
              rule: rows[i],
              counted: model.counted(rows[i]),
              category: categories.categories
                  .where((item) => item.id == rows[i].categoryId)
                  .firstOrNull,
              digits: model.digitsFor(rows[i].currencyCode),
              onChanged: model.busy
                  ? null
                  : (on) => model.toggle(rows[i], counts: on),
            ),
          ],
        ],
      ),
    );
  }
}
