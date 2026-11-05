import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/widgets/freeva_sheet.dart';

/// Calendar sheet for a goal's target date. Returns `YYYY-MM-DD`, `''` when
/// the user cleared it ([clearable] only), or null when dismissed.
Future<String?> showGoalDateSheet(
  BuildContext context, {
  required DateTime firstDate,
  String? current,
  bool clearable = false,
}) {
  final s = S.of(context);
  return showFreevaSheet<String>(
    context: context,
    title: s.goalDate,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CalendarDatePicker(
          initialDate: current == null
              ? firstDate.add(const Duration(days: 30))
              : DateTime.parse(current),
          firstDate: firstDate,
          lastDate: DateTime(firstDate.year + 60, 12, 31),
          onDateChanged: (d) =>
              Navigator.of(context).pop(DateFormat('yyyy-MM-dd').format(d)),
        ),
        if (clearable && current != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop(''),
            child: Text(s.goalDateClear),
          ),
      ],
    ),
  );
}
