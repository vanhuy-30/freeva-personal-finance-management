import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_dialog.dart';
import '../../../notifications/domain/notification_models.dart';

/// Popup "Chọn giờ nhắc" (board N6 `NotifyTime`): hour and minute wheels,
/// minutes in steps of [dailyLogMinuteStep]. Returns `HH:mm`, null on cancel.
Future<String?> showDailyLogTimePicker(
  BuildContext context, {
  required String initial,
}) => showDialog<String>(
  context: context,
  builder: (context) => DailyLogTimeDialog(initial: initial),
);

class DailyLogTimeDialog extends StatefulWidget {
  const DailyLogTimeDialog({required this.initial, super.key});

  /// Saved time from the API (`HH:mm`); snapped to the minute step.
  final String initial;

  @override
  State<DailyLogTimeDialog> createState() => _DailyLogTimeDialogState();
}

const _minuteSlots = 60 ~/ dailyLogMinuteStep;

class _DailyLogTimeDialogState extends State<DailyLogTimeDialog> {
  late final (int, int) _start = snapDailyLogTime(widget.initial);
  late int _hour = _start.$1;
  late int _minute = _start.$2;
  // Loop wheels start far from 0 so both directions scroll freely.
  late final _hours = FixedExtentScrollController(
    initialItem: 24 * 50 + _start.$1,
  );
  late final _minutes = FixedExtentScrollController(
    initialItem: _minuteSlots * 50 + _start.$2 ~/ dailyLogMinuteStep,
  );

  @override
  void dispose() {
    _hours.dispose();
    _minutes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final picked = formatHm(_hour, _minute);
    return FreevaDialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.statusWarningBg,
                    borderRadius: BorderRadius.circular(FreevaRadius.sm),
                  ),
                  child: Icon(
                    LucideIcons.clock,
                    size: FreevaSize.iconInline,
                    color: c.statusWarning,
                  ),
                ),
              ),
              const SizedBox(width: FreevaSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        s.notifyTimeTitle,
                        style: FreevaTypography.titleL.copyWith(
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      s.notifyTimeHint,
                      style: FreevaTypography.bodyS.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: FreevaSpace.s4),
          SizedBox(
            height: _wheelHeight + 8,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 40,
                  right: 40,
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: c.bgSubtle,
                      borderRadius: BorderRadius.circular(FreevaRadius.smd),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Wheel(
                      label: s.notifyTimeHour,
                      controller: _hours,
                      count: 24,
                      selected: _hour,
                      text: (i) => i.toString().padLeft(2, '0'),
                      onChanged: (i) => setState(() => _hour = i),
                    ),
                    const SizedBox(width: 18),
                    ExcludeSemantics(
                      child: Text(
                        ':',
                        style: FreevaTypography.titleL.copyWith(
                          fontSize: 26,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    _Wheel(
                      label: s.notifyTimeMinute,
                      controller: _minutes,
                      count: _minuteSlots,
                      selected: _minute ~/ dailyLogMinuteStep,
                      text: (i) =>
                          (i * dailyLogMinuteStep).toString().padLeft(2, '0'),
                      onChanged: (i) =>
                          setState(() => _minute = i * dailyLogMinuteStep),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: FreevaSpace.s4),
          Row(
            children: [
              Expanded(
                child: FreevaButton(
                  label: s.commonCancel,
                  variant: FreevaButtonVariant.secondary,
                  size: FreevaButtonSize.dialog,
                  expand: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: FreevaSpace.s2),
              Expanded(
                child: FreevaButton(
                  label: s.notifyTimePick(picked),
                  size: FreevaButtonSize.dialog,
                  expand: true,
                  onPressed: () => Navigator.of(context).pop(picked),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Five rows of 40 with 4 between (board), so one item is 44.
const _itemExtent = 44.0;
const _wheelHeight = _itemExtent * 5 - 4;

class _Wheel extends StatelessWidget {
  const _Wheel({
    required this.label,
    required this.controller,
    required this.count,
    required this.selected,
    required this.text,
    required this.onChanged,
  });

  final String label;
  final FixedExtentScrollController controller;
  final int count;
  final int selected;
  final String Function(int) text;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: label,
      value: text(selected),
      child: SizedBox(
        width: 56,
        height: _wheelHeight,
        child: ListWheelScrollView.useDelegate(
          controller: controller,
          itemExtent: _itemExtent,
          diameterRatio: 100,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: (i) => onChanged(i % count),
          childDelegate: ListWheelChildLoopingListDelegate(
            children: [
              for (var i = 0; i < count; i++)
                Center(
                  child: Text(
                    text(i),
                    style: i == selected
                        ? FreevaTypography.moneyL.copyWith(
                            letterSpacing: 0,
                            color: c.textPrimary,
                          )
                        : FreevaTypography.body.copyWith(
                            fontSize: 20,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            color: c.textMuted,
                          ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
