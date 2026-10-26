import 'package:flutter/material.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.g.dart';
import '../../../../../core/widgets/freeva_button.dart';
import '../../../../../core/widgets/freeva_picker_field.dart';

/// What the day popup returns; [day] null means "Để trống".
class DayChoice {
  const DayChoice(this.day);
  final int? day;
}

/// Centered popup "Đến hạn ngày nào? · Hằng tháng" with days 1–28 (D, màn 7).
/// [marked] (the other card day) gets a grey dot. Null when cancelled.
Future<DayChoice?> showDayOfMonthPicker(
  BuildContext context, {
  required String title,
  required FieldIconTile icon,
  required int? selected,
  int? marked,
  String? markLabel,
}) => showDialog<DayChoice>(
  context: context,
  builder: (context) => _DayDialog(
    title: title,
    icon: icon,
    initial: selected,
    marked: marked,
    markLabel: markLabel,
  ),
);

class _DayDialog extends StatefulWidget {
  const _DayDialog({
    required this.title,
    required this.icon,
    required this.initial,
    required this.marked,
    required this.markLabel,
  });

  final String title;
  final FieldIconTile icon;
  final int? initial;
  final int? marked;
  final String? markLabel;

  @override
  State<_DayDialog> createState() => _DayDialogState();
}

class _DayDialogState extends State<_DayDialog> {
  late int? day = widget.initial;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final picked = day;
    return Dialog(
      backgroundColor: c.sheetBg,
      insetPadding: EdgeInsets.symmetric(horizontal: context.screenMargin),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FreevaRadius.sheet),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                SizedBox.square(
                  dimension: 40,
                  child: FittedBox(child: widget.icon),
                ),
                const SizedBox(width: FreevaSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          widget.title,
                          style: FreevaTypography.titleL.copyWith(
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        s.dayMonthly,
                        style: FreevaTypography.bodyS.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _DayGrid(
              selected: picked,
              marked: widget.marked,
              markLabel: widget.markLabel,
              // Tapping the chosen day again clears it.
              onTap: (value) =>
                  setState(() => day = value == day ? null : value),
            ),
            if (widget.marked != null && widget.markLabel != null) ...[
              const SizedBox(height: 14),
              ExcludeSemantics(
                child: Row(
                  children: [
                    const SizedBox(width: 2),
                    _Dot(color: c.textSecondary, size: 6),
                    const SizedBox(width: 6),
                    Text(
                      widget.markLabel!,
                      style: FreevaTypography.label.copyWith(
                        fontWeight: FontWeight.w400,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FreevaButton(
                    label: s.commonCancel,
                    variant: FreevaButtonVariant.secondary,
                    size: FreevaButtonSize.s,
                    expand: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: FreevaSpace.s2),
                Expanded(
                  child: FreevaButton(
                    label: picked == null ? s.dayClear : s.dayConfirm(picked),
                    size: FreevaButtonSize.s,
                    expand: true,
                    onPressed: () =>
                        Navigator.of(context).pop(DayChoice(picked)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 7 columns, days 1–28 (no month has fewer).
class _DayGrid extends StatelessWidget {
  const _DayGrid({
    required this.selected,
    required this.marked,
    required this.markLabel,
    required this.onTap,
  });

  final int? selected;
  final int? marked;
  final String? markLabel;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    Widget cell(int day) {
      final on = day == selected;
      final dot = day == marked && !on;
      final label = day == marked && markLabel != null
          ? s.dayMarkedSemantics(day, markLabel!)
          : '$day';
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Semantics(
            container: true,
            button: true,
            inMutuallyExclusiveGroup: true,
            checked: on,
            label: label,
            onTap: () => onTap(day),
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(day),
              child: Container(
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on ? c.actionPrimary : null,
                  borderRadius: BorderRadius.circular(FreevaRadius.full),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Text(
                      '$day',
                      style: FreevaTypography.body.copyWith(
                        fontWeight: on ? FontWeight.w600 : FontWeight.w500,
                        color: on
                            ? c.textOnAction
                            : dot
                            ? c.textSecondary
                            : c.textPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (dot)
                      Positioned(
                        bottom: -9,
                        child: _Dot(color: c.textSecondary, size: 4),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var week = 0; week < 4; week++)
          Row(children: [for (var i = 1; i <= 7; i++) cell(week * 7 + i)]),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
