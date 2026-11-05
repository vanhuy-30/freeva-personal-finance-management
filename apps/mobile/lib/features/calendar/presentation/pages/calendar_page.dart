import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_retry.dart';
import '../../../../core/widgets/freeva_icon_button.dart';
import '../../../../core/widgets/freeva_sheet.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../domain/calendar_month.dart';
import '../viewmodels/calendar_view_model.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late final CalendarViewModel model = getIt<CalendarViewModel>();

  @override
  void initState() {
    super.initState();
    Future.microtask(model.load);
  }

  DateTime get _monthDate {
    final parts = model.selectedMonth.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
  }

  int _digits(String code) => code == 'VND' ? 0 : 2;

  Future<void> _openDay(String date) async {
    final day = model.month?.dayOn(date);
    if (day == null) return;
    final s = S.of(context);
    final locale = Localizations.localeOf(context).toString();
    final title = DateFormat.yMMMMd(locale).format(DateTime.parse(date));
    await showFreevaSheet<void>(
      context: context,
      title: title,
      builder: (context) => _DaySheet(
        day: day,
        labels: (
          transactions: s.calendarSectionTransactions,
          recurring: s.calendarSectionRecurring,
          bills: s.calendarSectionBills,
          paid: s.billsStatusPaid,
          overdue: s.billsStatusOverdue,
          open: s.billsStatusOpen,
          transfer: s.calendarTransfer,
          estimated: s.calendarEstimated,
        ),
        formatAmount: (minor, code) =>
            formatMoneyText(minor, _digits(code), locale),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    return Scaffold(
      appBar: FreevaTopBar(
        title: s.calendarTitle,
        onLeading: () => context.popOrGo('/me'),
      ),
      body: ListenableBuilder(
        listenable: model,
        builder: (context, _) {
          if (!model.loaded && model.failure != null) {
            return ErrorRetry(
              title: s.calendarLoadError,
              message: s.homeErrorBody,
              onRetry: model.load,
            );
          }
          if (!model.loaded) {
            return const Padding(
              padding: EdgeInsets.all(FreevaSpace.s4),
              child: SkeletonRows(count: 6),
            );
          }
          final data = model.month!;
          final monthLabel = DateFormat.yMMMM(locale).format(_monthDate);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  FreevaSpace.s2,
                  FreevaSpace.s3,
                  FreevaSpace.s2,
                  FreevaSpace.s2,
                ),
                child: Row(
                  children: [
                    FreevaIconButton(
                      icon: LucideIcons.chevronLeft,
                      label: s.calendarPrevMonth,
                      onPressed: model.loading
                          ? null
                          : () => model.shiftMonth(-1),
                    ),
                    Expanded(
                      child: Text(
                        monthLabel,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    FreevaIconButton(
                      icon: LucideIcons.chevronRight,
                      label: s.calendarNextMonth,
                      onPressed: model.loading
                          ? null
                          : () => model.shiftMonth(1),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: FreevaSpace.s4),
                child: _MonthGrid(
                  month: _monthDate,
                  data: data,
                  today: data.today,
                  weekdayNames: s.reportWeekdays.split(','),
                  onTap: _openDay,
                  colors: c,
                ),
              ),
              if (data.days.isEmpty)
                Expanded(
                  child: EmptyState(
                    title: s.calendarEmptyTitle,
                    message: s.calendarEmptyBody,
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(FreevaSpace.s4),
                    children: [
                      Text(
                        s.calendarLegend,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: c.textSecondary),
                      ),
                      const SizedBox(height: FreevaSpace.s2),
                      Wrap(
                        spacing: FreevaSpace.s3,
                        runSpacing: FreevaSpace.s2,
                        children: [
                          _LegendDot(
                            color: c.tintBlueFg,
                            label: s.calendarSectionTransactions,
                          ),
                          _LegendDot(
                            color: c.statusWarning,
                            label: s.calendarSectionRecurring,
                          ),
                          _LegendDot(
                            color: c.tintCyanFg,
                            label: s.calendarSectionBills,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.data,
    required this.today,
    required this.weekdayNames,
    required this.onTap,
    required this.colors,
  });

  final DateTime month;
  final CalendarMonth data;
  final String today;
  final List<String> weekdayNames;
  final ValueChanged<String> onTap;
  final FreevaColors colors;

  @override
  Widget build(BuildContext context) {
    final lead = month.weekday - 1;
    final length = DateUtils.getDaysInMonth(month.year, month.month);
    final cells = <Widget>[
      for (final name in weekdayNames)
        SizedBox(
          height: 28,
          child: Center(
            child: Text(
              name,
              style: FreevaTypography.label.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
          ),
        ),
      for (var i = 0; i < lead; i++) const SizedBox(height: 48),
      for (var day = 1; day <= length; day++)
        _DayCell(
          iso: DateFormat('yyyy-MM-dd')
              .format(DateTime(month.year, month.month, day)),
          day: day,
          data: data,
          today: today,
          onTap: onTap,
          colors: colors,
        ),
    ];
    final rows = (cells.length / 7).ceil();
    return Table(
      children: [
        for (var r = 0; r < rows; r++)
          TableRow(
            children: [
              for (var i = 0; i < 7; i++)
                Padding(
                  padding: EdgeInsets.only(top: r == 0 ? 0 : FreevaSpace.s1),
                  child: r * 7 + i < cells.length
                      ? cells[r * 7 + i]
                      : const SizedBox.shrink(),
                ),
            ],
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.iso,
    required this.day,
    required this.data,
    required this.today,
    required this.onTap,
    required this.colors,
  });

  final String iso;
  final int day;
  final CalendarMonth data;
  final String today;
  final ValueChanged<String> onTap;
  final FreevaColors colors;

  @override
  Widget build(BuildContext context) {
    final entry = data.dayOn(iso);
    final isToday = iso == today;
    final has = entry != null;
    return Semantics(
      button: has,
      label: '$day',
      child: InkWell(
        onTap: has ? () => onTap(iso) : null,
        borderRadius: BorderRadius.circular(FreevaRadius.sm),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(FreevaRadius.sm),
            border: isToday
                ? Border.all(color: colors.borderStrong, width: 1.5)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$day',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                  color: has ? colors.textPrimary : colors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (entry?.hasTransactions == true)
                    _Dot(color: colors.tintBlueFg),
                  if (entry?.hasRecurring == true)
                    _Dot(color: colors.statusWarning),
                  if (entry?.hasBills == true) _Dot(color: colors.tintCyanFg),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Dot(color: color),
        const SizedBox(width: FreevaSpace.s1),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

typedef _DayLabels = ({
  String transactions,
  String recurring,
  String bills,
  String paid,
  String overdue,
  String open,
  String transfer,
  String estimated,
});

class _DaySheet extends StatelessWidget {
  const _DaySheet({
    required this.day,
    required this.labels,
    required this.formatAmount,
  });

  final CalendarDay day;
  final _DayLabels labels;
  final String Function(BigInt minor, String currencyCode) formatAmount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (day.transactions.isNotEmpty) ...[
          Text(labels.transactions, style: theme.textTheme.titleSmall),
          const SizedBox(height: FreevaSpace.s2),
          for (final item in day.transactions)
            _Line(
              title: item.categoryName ?? labels.transfer,
              amount: formatAmount(item.amountMinor, item.currencyCode),
            ),
          const SizedBox(height: FreevaSpace.s4),
        ],
        if (day.recurring.isNotEmpty) ...[
          Text(labels.recurring, style: theme.textTheme.titleSmall),
          const SizedBox(height: FreevaSpace.s2),
          for (final item in day.recurring)
            _Line(
              title: item.categoryName ?? labels.transfer,
              amount: formatAmount(item.amountMinor, item.currencyCode),
            ),
          const SizedBox(height: FreevaSpace.s4),
        ],
        if (day.bills.isNotEmpty) ...[
          Text(labels.bills, style: theme.textTheme.titleSmall),
          const SizedBox(height: FreevaSpace.s2),
          for (final item in day.bills)
            _Line(
              title: item.name,
              amount: formatAmount(item.amountMinor, item.currencyCode),
              subtitle: [
                if (item.paid)
                  labels.paid
                else if (item.overdue)
                  labels.overdue
                else
                  labels.open,
                if (item.amountKind == 'estimated') labels.estimated,
              ].join(' · '),
            ),
        ],
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.title, required this.amount, this.subtitle});

  final String title;
  final String amount;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: FreevaSpace.s2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyMedium),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: c.textSecondary),
                  ),
              ],
            ),
          ),
          Text(amount, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
