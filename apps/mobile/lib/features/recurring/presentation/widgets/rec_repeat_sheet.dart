import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_sheet.dart';

/// How often a rule repeats. [unit] is null for "Một lần".
typedef RecRepeat = ({String? unit, int interval});

/// "Lặp lại" choices: Một lần (bills only), then day, week, month, year.
Future<RecRepeat?> showRecRepeatSheet(
  BuildContext context, {
  required RecRepeat current,
  required bool allowOnce,
}) {
  final s = S.of(context);
  final options = <(RecRepeat, String)>[
    if (allowOnce) ((unit: null, interval: 1), s.recOnce),
    ((unit: 'day', interval: 1), s.recEveryDay),
    ((unit: 'week', interval: 1), s.recEveryWeek),
    ((unit: 'month', interval: 1), s.recEveryMonth),
    ((unit: 'year', interval: 1), s.recEveryYear),
  ];
  return showFreevaSheet<RecRepeat>(
    context: context,
    title: s.recRepeat,
    builder: (context) {
      final c = context.colors;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (value, label) in options)
            InkWell(
              onTap: () => Navigator.of(context).pop(value),
              child: Container(
                height: FreevaSize.row,
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: c.listDivider)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: FreevaTypography.body.copyWith(
                          fontWeight: value == current
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                    if (value == current)
                      Icon(LucideIcons.check, size: 18, color: c.actionPrimary),
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );
}
