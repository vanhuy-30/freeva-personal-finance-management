import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../domain/report_range.dart';

/// One month, weeks starting Monday. The range is a `tint.blue` strip with
/// primary ends, today has an outline, locked days are greyed.
class RangeCalendar extends StatelessWidget {
  const RangeCalendar({
    required this.month,
    required this.selection,
    required this.today,
    required this.onTap,
    super.key,
  });

  /// First day of the month shown.
  final DateTime month;
  final RangeSelection selection;
  final String today;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final names = s.reportWeekdays.split(',');
    final lead = month.weekday - 1;
    final length = DateUtils.getDaysInMonth(month.year, month.month);
    final cells = <Widget>[
      for (final name in names)
        Center(
          child: ExcludeSemantics(
            child: Text(
              name,
              style: FreevaTypography.label.copyWith(
                fontWeight: FontWeight.w600,
                color: c.textSecondary,
              ),
            ),
          ),
        ),
      for (var i = 0; i < lead; i++) const SizedBox.shrink(),
      for (var day = 1; day <= length; day++)
        _Day(
          iso: DateFormat('yyyy-MM-dd')
              .format(DateTime(month.year, month.month, day)),
          selection: selection,
          today: today,
          onTap: onTap,
        ),
    ];
    final rows = (cells.length / 7).ceil();
    return Table(
      children: [
        for (var r = 0; r < rows; r++)
          TableRow(
            children: [
              for (var i = 0; i < 7; i++)
                r * 7 + i < cells.length
                    ? cells[r * 7 + i]
                    : const SizedBox.shrink(),
            ],
          ),
      ],
    );
  }
}

class _Day extends StatelessWidget {
  const _Day({
    required this.iso,
    required this.selection,
    required this.today,
    required this.onTap,
  });

  final String iso;
  final RangeSelection selection;
  final String today;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locked = dayLocked(iso, selection, today);
    final end = iso == selection.from || iso == selection.to;
    final inside = selection.covers(iso) && !end;
    final isToday = iso == today;
    final short = DateFormat(
      s.reportShortDatePattern,
      Localizations.localeOf(context).toString(),
    ).format(DateTime.parse(iso));
    final label = iso == selection.from
        ? s.reportDayFrom(short)
        : iso == selection.to
        ? s.reportDayTo(short)
        : isToday
        ? s.reportDayToday(short)
        : '${int.parse(iso.substring(8))}';
    return Semantics(
      button: true,
      enabled: !locked,
      selected: end || inside,
      label: label,
      excludeSemantics: true,
      onTap: locked ? null : () => onTap(iso),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: locked ? null : () => onTap(iso),
        child: Container(
          constraints: const BoxConstraints(minHeight: 38),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: end
                ? c.actionPrimary
                : inside
                ? c.tintBlue
                : null,
            borderRadius: end ? BorderRadius.circular(FreevaRadius.full) : null,
            border: isToday && !end
                ? Border.all(color: c.textPrimary, width: 1.2)
                : null,
          ),
          child: Text(
            '${int.parse(iso.substring(8))}',
            style: FreevaTypography.body.copyWith(
              fontSize: 14,
              fontWeight: end ? FontWeight.w600 : FontWeight.w500,
              color: locked
                  ? c.textDisabled
                  : end
                  ? c.textOnAction
                  : inside
                  ? c.tintBlueFg
                  : c.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}
