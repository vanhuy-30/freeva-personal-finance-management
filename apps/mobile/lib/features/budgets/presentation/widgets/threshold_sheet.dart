import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/lucide_icons.g.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_chip.dart';
import '../../../../core/widgets/freeva_sheet.dart';

/// Levels offered as chips; a saved budget with other levels adds them.
const thresholdChoices = [70, 80, 90, 100];

/// Most levels a budget can alert on.
const maxThresholds = 4;

/// Turns [value] on or off in [current] (sorted). Ignores a fifth level and
/// never leaves the list empty.
List<int> toggleThreshold(List<int> current, int value) {
  if (current.contains(value)) {
    if (current.length == 1) return current;
    return [
      for (final t in current)
        if (t != value) t,
    ];
  }
  if (current.length >= maxThresholds) return current;
  return ([...current, value]..sort());
}

/// "Báo khi đã dùng": multi-select of alert levels. Returns the chosen levels
/// (sorted) or null when dismissed.
Future<List<int>?> showThresholdSheet(
  BuildContext context, {
  required List<int> selected,
}) {
  final s = S.of(context);
  return showFreevaSheet<List<int>>(
    context: context,
    title: s.budgetThresholdsSheetTitle,
    subtitle: s.budgetThresholdsSheetSub,
    titleGap: 18,
    builder: (_) => _ThresholdSheetBody(initial: selected),
  );
}

class _ThresholdSheetBody extends StatefulWidget {
  const _ThresholdSheetBody({required this.initial});

  final List<int> initial;

  @override
  State<_ThresholdSheetBody> createState() => _ThresholdSheetBodyState();
}

class _ThresholdSheetBodyState extends State<_ThresholdSheetBody> {
  late List<int> _picked = List.of(widget.initial)..sort();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final options = ({...thresholdChoices, ...widget.initial}.toList()..sort());
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: FreevaSpace.s2,
          runSpacing: FreevaSpace.s2,
          children: [
            for (final value in options)
              FreevaChip(
                label: '$value%',
                selected: _picked.contains(value),
                icon: _picked.contains(value) ? LucideIcons.check : null,
                onTap: () =>
                    setState(() => _picked = toggleThreshold(_picked, value)),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.only(left: FreevaSpace.s1),
          child: Text(
            s.budgetThresholdsDefaultHint,
            style: FreevaTypography.bodyS.copyWith(
              fontSize: 13,
              color: c.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 18),
        FreevaButton(
          label: s.budgetSave,
          onPressed: () => Navigator.of(context).pop(_picked),
        ),
      ],
    );
  }
}
