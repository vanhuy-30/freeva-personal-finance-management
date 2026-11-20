import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../domain/overview_glance.dart';
import 'glance_tile.dart';

/// "Sắp phải trả": total due by the end of the month, the count, and a tag
/// for the nearest item (amber; red when overdue). Opens the calendar.
class UpcomingTile extends StatelessWidget {
  const UpcomingTile({
    required this.summary,
    required this.today,
    required this.digits,
    super.key,
  });

  final UpcomingSummary summary;
  final DateTime today;
  final int digits;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final nearest = summary.nearest;
    final name = nearest.name ?? s.homeUpcomingRecurring;
    final day = DateTime(today.year, today.month, today.day);
    final days = nearest.dueOn.difference(day).inDays;
    final overdue = days < 0;
    final tag = overdue
        ? s.homeUpcomingOverdue(name)
        : days == 0
        ? s.homeUpcomingToday(name)
        : s.homeUpcomingDays(name, days);
    final total = formatMoneyText(summary.totalMinor, digits, locale);
    final count = s.homeUpcomingCount(
      summary.count,
      DateFormat('dd/MM', locale).format(summary.until),
    );
    return GlanceTile(
      semanticsLabel: '${s.homeUpcomingTitle} $total, $count, $tag',
      onTap: () => context.push('/me/calendar'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GlanceHeader(
            icon: LucideIcons.receiptText,
            label: s.homeUpcomingTitle,
            bg: c.statusWarningBg,
            fg: c.statusWarning,
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(total, style: glanceBig(context)),
              ),
              const SizedBox(height: 2),
              Text(count, maxLines: 1, style: glanceNote(context)),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: GlanceTag(
              text: tag,
              bg: overdue ? c.statusDangerBg : c.statusWarningBg,
              fg: overdue ? c.statusDanger : c.statusWarning,
            ),
          ),
        ],
      ),
    );
  }
}
