import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_retry.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/freeva_chip.dart';
import '../../../../core/widgets/freeva_icon_button.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../../core/widgets/money_display.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../../profile/presentation/viewmodels/profile_view_model.dart';
import '../../domain/month_review_format.dart';
import '../../domain/report.dart';
import '../../domain/report_use_cases.dart';
import '../viewmodels/month_review_view_model.dart';
import '../widgets/report_labels.dart';
import '../widgets/report_period_labels.dart';

/// Pushed screen: one fiscal month's income, expense, savings, rate, top 3.
class MonthReviewPage extends StatefulWidget {
  const MonthReviewPage({this.on, super.key});

  /// Anchor calendar date for the fiscal month; null = today on the server.
  final String? on;

  @override
  State<MonthReviewPage> createState() => _MonthReviewPageState();
}

class _MonthReviewPageState extends State<MonthReviewPage> {
  late final MonthReviewViewModel model = MonthReviewViewModel(
    getIt<ReportUseCases>(),
    getIt<AuthViewModel>(),
    getIt<ProfileViewModel>(),
    initialOn: widget.on,
  );

  @override
  void initState() {
    super.initState();
    Future.microtask(() => model.load(on: widget.on));
  }

  @override
  void dispose() {
    model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final margin = context.screenMargin;
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) => Scaffold(
        appBar: FreevaTopBar(
          title: s.monthReviewTitle,
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
              _Stepper(model: model),
              const SizedBox(height: FreevaSpace.s4),
              ..._body(context),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _body(BuildContext context) {
    final s = S.of(context);
    const gap = SizedBox(height: FreevaSpace.s4);
    if (model.failure != null && model.data == null && !model.busy) {
      return [
        ErrorRetry(
          title: reportFailure(s, model.failure!),
          message: s.homeErrorBody,
          onRetry: model.reload,
        ),
      ];
    }
    if (model.data == null) {
      return [
        const SkeletonBox(height: 160, radius: 24),
        gap,
        const SkeletonBox(height: 180, radius: 24),
      ];
    }
    final period = model.data!.report.period;
    final selected = model.selected;
    if (selected == null) {
      return [_Empty(model: model, period: period)];
    }
    final digits = model.data!.digitsOf(selected.currency);
    return [
      if (model.currencies.length > 1) ...[
        Wrap(
          spacing: FreevaSpace.s2,
          runSpacing: FreevaSpace.s2,
          children: [
            for (final code in model.currencies)
              FreevaChip(
                kind: FreevaChipKind.filter,
                label: code,
                selected: code == model.currency,
                onTap: () => model.selectCurrency(code),
              ),
          ],
        ),
        gap,
      ],
      _TotalsCard(row: selected, digits: digits),
      gap,
      _TopCategoriesCard(row: selected, digits: digits),
    ];
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.model});

  final MonthReviewViewModel model;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final period = model.data?.report.period;
    final title = period == null
        ? null
        : periodTitle(s, period, Localizations.localeOf(context).toString());
    return Row(
      children: [
        FreevaIconButton(
          icon: LucideIcons.chevronLeft,
          label: s.reportPrevious,
          kind: FreevaIconButtonKind.stepper,
          onPressed: model.canStep ? () => model.step(-1) : null,
        ),
        Expanded(
          child: title == null
              ? const Center(child: SkeletonBox(width: 120, height: 36))
              : Column(
                  children: [
                    Text(
                      title.title,
                      textAlign: TextAlign.center,
                      style: FreevaTypography.titleL.copyWith(
                        height: 1.2,
                        color: c.textPrimary,
                      ),
                    ),
                    if (title.subtitle != null)
                      Text(
                        title.subtitle!,
                        style: FreevaTypography.label.copyWith(
                          fontWeight: FontWeight.w400,
                          color: c.textSecondary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                  ],
                ),
        ),
        FreevaIconButton(
          icon: LucideIcons.chevronRight,
          label: s.reportNext,
          kind: FreevaIconButtonKind.stepper,
          onPressed: model.canStepNext ? () => model.step(1) : null,
        ),
      ],
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.row, required this.digits});

  final MonthReviewCurrency row;
  final int digits;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final locale = Localizations.localeOf(context).toString();
    final rate = row.savingsRateBps;
    Widget money(BigInt minor, MoneyTone tone) => MoneyDisplay(
      minor: minor,
      currency: row.currency,
      minorDigits: digits,
      tone: tone,
      showCurrency: false,
      style: FreevaTypography.titleL.copyWith(
        fontSize: 20,
        height: 1.2,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
    final cells = [
      _Cell(s.reportIncome, money(row.incomeMinor, MoneyTone.income)),
      _Cell(s.reportExpense, money(row.expenseMinor, MoneyTone.expense)),
      _Cell(s.monthReviewSavings, money(row.savingsMinor, MoneyTone.plain)),
      _Cell(
        s.monthReviewSavingsRate,
        Text(
          rate == null ? '—' : formatSavingsRateBps(rate, locale),
          style: FreevaTypography.titleL.copyWith(
            fontSize: 20,
            height: 1.2,
            color: context.colors.textPrimary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    ];
    return FreevaCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: cells[0]),
              const SizedBox(width: FreevaSpace.s3),
              Expanded(child: cells[1]),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: cells[2]),
              const SizedBox(width: FreevaSpace.s3),
              Expanded(child: cells[3]),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopCategoriesCard extends StatelessWidget {
  const _TopCategoriesCard({required this.row, required this.digits});

  final MonthReviewCurrency row;
  final int digits;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    if (row.topCategories.isEmpty) {
      return FreevaCard(
        padding: const EdgeInsets.all(18),
        child: Text(
          s.monthReviewNoCategories,
          style: FreevaTypography.bodyM.copyWith(color: c.textSecondary),
        ),
      );
    }
    return FreevaCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.monthReviewTopCategories,
            style: FreevaTypography.titleM.copyWith(color: c.textPrimary),
          ),
          const SizedBox(height: FreevaSpace.s3),
          for (var i = 0; i < row.topCategories.length; i++) ...[
            if (i > 0) Divider(height: 1, color: c.borderDivider),
            _CategoryRow(
              index: i + 1,
              category: row.topCategories[i],
              currency: row.currency,
              digits: digits,
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.index,
    required this.category,
    required this.currency,
    required this.digits,
  });

  final int index;
  final MonthReviewCategory category;
  final String currency;
  final int digits;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final name = category.name ?? s.homeUncategorized;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Text(
            '$index.',
            style: FreevaTypography.bodyM.copyWith(
              color: c.textSecondary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: FreevaSpace.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: FreevaTypography.bodyM.copyWith(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (category.parentName != null)
                  Text(
                    category.parentName!,
                    style: FreevaTypography.label.copyWith(
                      color: c.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          MoneyDisplay(
            minor: category.expenseMinor,
            currency: currency,
            minorDigits: digits,
            tone: MoneyTone.expense,
            showCurrency: false,
            style: FreevaTypography.bodyM.copyWith(
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.label, this.value);

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: FreevaTypography.label.copyWith(
            fontWeight: FontWeight.w400,
            color: c.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        value,
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.model, required this.period});

  final MonthReviewViewModel model;
  final ReportPeriod period;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final from = DateTime.parse(period.from);
    final title = from.day == 1
        ? s.reportEmptyTitleMonth('${from.month}')
        : s.reportEmptyTitle(
            periodTitle(
              s,
              period,
              Localizations.localeOf(context).toString(),
            ).title.toLowerCase(),
          );
    final back = !model.atCurrent;
    return Padding(
      padding: const EdgeInsets.only(top: 72 - FreevaSpace.s6),
      child: Center(
        child: EmptyState(
          title: title,
          message: back ? null : s.reportEmptyHint,
          actionLabel: back ? s.reportBackMonth : null,
          onAction: back ? model.backToCurrent : null,
        ),
      ),
    );
  }
}
