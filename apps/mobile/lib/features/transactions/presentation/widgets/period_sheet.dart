import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/freeva_sheet.dart';
import '../../domain/transaction_filter.dart';

/// Quick period pick for search: Mọi lúc · Tuần này · Tháng này · Tháng trước.
Future<PeriodPreset?> showPeriodSheet(
  BuildContext context,
  PeriodPreset current,
) {
  final s = S.of(context);
  final options = [
    (PeriodPreset.allTime, s.txPeriodAllTime),
    (PeriodPreset.thisWeek, s.txPeriodThisWeek),
    (PeriodPreset.thisMonth, s.txPeriodThisMonth),
    (PeriodPreset.lastMonth, s.txPeriodLastMonth),
  ];
  return showFreevaSheet<PeriodPreset>(
    context: context,
    title: s.txFilterPeriod,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (value, label) in options)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(label),
            trailing: value == current
                ? Icon(LucideIcons.check, color: context.colors.actionPrimary)
                : null,
            onTap: () => Navigator.of(context).pop(value),
          ),
      ],
    ),
  );
}
