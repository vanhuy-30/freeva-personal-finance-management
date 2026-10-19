import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../domain/report_period.dart';
import '../viewmodels/report_view_model.dart';
import 'report_money.dart';

class ReportRangeFields extends StatelessWidget {
  const ReportRangeFields({required this.model, super.key});

  final ReportViewModel model;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final ready =
        model.rangeFrom != null && model.rangeTo != null && !model.busy;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        TextButton(
          onPressed: model.busy ? null : () => _pick(context, start: true),
          child: Text(model.rangeFrom ?? s.reportFrom),
        ),
        TextButton(
          onPressed: model.busy ? null : () => _pick(context, start: false),
          child: Text(model.rangeTo ?? s.reportTo),
        ),
        FilledButton(
          onPressed: ready ? model.applyRange : null,
          child: Text(s.reportApply),
        ),
      ],
    );
  }

  Future<void> _pick(BuildContext context, {required bool start}) async {
    final current = start ? model.rangeFrom : model.rangeTo;
    final picked = await showDatePicker(
      context: context,
      initialDate: _initial(current),
      firstDate: DateTime(1, 1, 1),
      lastDate: DateTime(9999, 12, 31),
    );
    if (picked == null) return;
    final iso = calendarDate(picked);
    model.setRangeEdge(from: start ? iso : null, to: start ? null : iso);
  }
}

DateTime _initial(String? iso) {
  if (iso != null && isCalendarDate(iso)) {
    final parts = iso.split('-').map(int.parse).toList();
    return DateTime(parts[0], parts[1], parts[2]);
  }
  return DateTime.now();
}
