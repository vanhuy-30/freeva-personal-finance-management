import 'package:flutter/material.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.g.dart';
import '../../../../../core/widgets/freeva_button.dart';
import '../../../../../core/widgets/freeva_chip.dart';
import '../../../../../core/widgets/freeva_sheet.dart';

/// Result of the C2.3 Thời gian sheet: calendar day plus optional `HH:mm`.
class DateTimePick {
  const DateTimePick({required this.date, this.time});
  final String date;
  final String? time;
}

/// Freeva sheet: today/yesterday + month calendar + optional 24h time.
Future<DateTimePick?> showDateTimePickerSheet(
  BuildContext context, {
  required String date,
  required String today,
  String? time,
}) {
  final s = S.of(context);
  DateTime parse(String d) => DateTime(
    int.parse(d.substring(0, 4)),
    int.parse(d.substring(5, 7)),
    int.parse(d.substring(8, 10)),
  );
  String fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String hm(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  TimeOfDay? parseHm(String? value) {
    if (value == null || value.length != 5) return null;
    final hour = int.tryParse(value.substring(0, 2));
    final minute = int.tryParse(value.substring(3, 5));
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  final now = parse(today);
  final yesterday = fmt(now.subtract(const Duration(days: 1)));
  var selectedDate = date.isEmpty ? today : date;
  var selectedTime = time;

  return showFreevaSheet<DateTimePick>(
    context: context,
    title: s.txDateTimeTitle,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final c = context.colors;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              children: [
                FreevaChip(
                  label: s.txToday,
                  selected: selectedDate == today,
                  onTap: () => setState(() => selectedDate = today),
                ),
                FreevaChip(
                  label: s.txYesterday,
                  selected: selectedDate == yesterday,
                  onTap: () => setState(() => selectedDate = yesterday),
                ),
              ],
            ),
            const SizedBox(height: FreevaSpace.s2),
            CalendarDatePicker(
              initialDate: parse(selectedDate),
              firstDate: DateTime(1900),
              lastDate: DateTime(2100, 12, 31),
              onDateChanged: (d) => setState(() => selectedDate = fmt(d)),
            ),
            const SizedBox(height: FreevaSpace.s2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.txTimeLabel,
                    style: FreevaTypography.body.copyWith(
                      fontWeight: FontWeight.w500,
                      color: c.textPrimary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime:
                          parseHm(selectedTime) ??
                          const TimeOfDay(hour: 12, minute: 0),
                      builder: (context, child) => MediaQuery(
                        data: MediaQuery.of(
                          context,
                        ).copyWith(alwaysUse24HourFormat: true),
                        child: child!,
                      ),
                    );
                    if (picked == null) return;
                    setState(() => selectedTime = hm(picked));
                  },
                  child: Text(
                    selectedTime ?? s.txTimeNone,
                    style: FreevaTypography.body.copyWith(
                      fontWeight: FontWeight.w500,
                      color: selectedTime == null
                          ? c.textSecondary
                          : c.textPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                if (selectedTime != null)
                  TextButton(
                    onPressed: () => setState(() => selectedTime = null),
                    child: Text(s.txTimeClear),
                  ),
              ],
            ),
            const SizedBox(height: FreevaSpace.s3),
            FreevaButton(
              label: s.txDateTimeDone,
              expand: true,
              onPressed: () => Navigator.of(context).pop(
                DateTimePick(date: selectedDate, time: selectedTime),
              ),
            ),
          ],
        );
      },
    ),
  );
}
