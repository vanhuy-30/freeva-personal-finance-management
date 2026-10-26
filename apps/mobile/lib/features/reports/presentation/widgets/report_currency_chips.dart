import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_chip.dart';
import '../viewmodels/report_view_model.dart';

/// One chip per currency with activity in the period. Amounts of different
/// currencies are never added up, so the screen shows one at a time.
class ReportCurrencyChips extends StatelessWidget {
  const ReportCurrencyChips({required this.model, super.key});

  final ReportViewModel model;

  @override
  Widget build(BuildContext context) => Wrap(
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
  );
}
