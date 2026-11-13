import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/lucide_icons.g.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_chip.dart';
import '../../../../core/widgets/freeva_sheet.dart';
import '../../../server_config/domain/app_limits.dart';

/// Turns [value] on or off in [current] (sorted). Ignores a level past [max]
/// (server `budget.maxAlertThresholds`) and never leaves the list empty.
List<int> toggleThreshold(List<int> current, int value, {required int max}) {
  if (current.contains(value)) {
    if (current.length == 1) return current;
    return [
      for (final t in current)
        if (t != value) t,
    ];
  }
  if (current.length >= max) return current;
  return ([...current, value]..sort());
}

/// "Báo khi đã dùng": multi-select of alert levels. Returns the chosen levels
/// (sorted) or null when dismissed.
Future<List<int>?> showThresholdSheet(
  BuildContext context, {
  required List<int> selected,
  AppLimits? limits,
}) {
  final s = S.of(context);
  final rules = limits ?? getIt<AppLimitsSource>().requireLimits;
  return showFreevaSheet<List<int>>(
    context: context,
    title: s.budgetThresholdsSheetTitle,
    subtitle: s.budgetThresholdsSheetSub(rules.budgetMaxThresholds),
    titleGap: 18,
    builder: (_) => _ThresholdSheetBody(initial: selected, limits: rules),
  );
}

/// "80% và 100%" from a list of levels.
String percentLevels(S s, List<int> levels) {
  final parts = [for (final level in levels) '$level%'];
  if (parts.length < 2) return parts.join();
  return '${parts.sublist(0, parts.length - 1).join(', ')} ${s.commonAnd} ${parts.last}';
}

class _ThresholdSheetBody extends StatefulWidget {
  const _ThresholdSheetBody({required this.initial, required this.limits});

  final List<int> initial;
  final AppLimits limits;

  @override
  State<_ThresholdSheetBody> createState() => _ThresholdSheetBodyState();
}

class _ThresholdSheetBodyState extends State<_ThresholdSheetBody> {
  late List<int> _picked = List.of(widget.initial)..sort();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final rules = widget.limits;
    final options = ({
      ...rules.budgetThresholdOptions,
      ...widget.initial,
    }.toList()..sort());
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
                onTap: () => setState(
                  () => _picked = toggleThreshold(
                    _picked,
                    value,
                    max: rules.budgetMaxThresholds,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.only(left: FreevaSpace.s1),
          child: Text(
            s.budgetThresholdsDefaultHint(
              percentLevels(s, rules.budgetDefaultThresholds),
            ),
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
