import 'package:flutter/material.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/theme/tokens.g.dart';
import '../../../../../core/widgets/freeva_chip.dart';
import '../../../../../core/widgets/freeva_sheet.dart';

/// Freeva date sheet: "Hôm nay" / "Hôm qua" chips and a month calendar.
/// Returns `yyyy-MM-dd`.
Future<String?> showDatePickerSheet(
  BuildContext context, {
  required String value,
  required String today,
}) {
  final s = S.of(context);
  DateTime parse(String d) => DateTime(
    int.parse(d.substring(0, 4)),
    int.parse(d.substring(5, 7)),
    int.parse(d.substring(8, 10)),
  );
  String fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  final now = parse(today);
  final yesterday = fmt(now.subtract(const Duration(days: 1)));
  return showFreevaSheet<String>(
    context: context,
    title: s.txDateTitle,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: [
            FreevaChip(
              label: s.txToday,
              selected: value == today,
              onTap: () => Navigator.of(context).pop(today),
            ),
            FreevaChip(
              label: s.txYesterday,
              selected: value == yesterday,
              onTap: () => Navigator.of(context).pop(yesterday),
            ),
          ],
        ),
        const SizedBox(height: FreevaSpace.s2),
        CalendarDatePicker(
          initialDate: parse(value.isEmpty ? today : value),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100, 12, 31),
          onDateChanged: (d) => Navigator.of(context).pop(fmt(d)),
        ),
      ],
    ),
  );
}
