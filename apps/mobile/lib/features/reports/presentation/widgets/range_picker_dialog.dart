import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_chip.dart';
import '../../../../core/widgets/freeva_icon_button.dart';
import '../../domain/report_range.dart';
import 'range_calendar.dart';

/// "Chọn khoảng ngày": quick picks, a month calendar and the summary line.
/// Returns the full range, or null when cancelled.
Future<RangeSelection?> showRangePicker(
  BuildContext context, {
  required String today,
  RangeSelection initial = const RangeSelection(),
}) => showDialog<RangeSelection>(
  context: context,
  builder: (context) => _RangeDialog(today: today, initial: initial),
);

class _RangeDialog extends StatefulWidget {
  const _RangeDialog({required this.today, required this.initial});

  final String today;
  final RangeSelection initial;

  @override
  State<_RangeDialog> createState() => _RangeDialogState();
}

class _RangeDialogState extends State<_RangeDialog> {
  late RangeSelection selection = widget.initial;
  late DateTime month = _firstOf(widget.initial.to ?? widget.today);

  DateTime _firstOf(String iso) {
    final day = DateTime.parse(iso);
    return DateTime(day.year, day.month);
  }

  bool get _atCurrentMonth => !month.isBefore(_firstOf(widget.today));

  void _shift(int by) =>
      setState(() => month = DateTime(month.year, month.month + by));

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final short = DateFormat(s.reportShortDatePattern, locale);
    final summary = selection.complete
        ? '${s.reportPeriod(short.format(DateTime.parse(selection.from!)), short.format(DateTime.parse(selection.to!)))}'
              ' · ${s.reportRangeDays(selection.days!)}'
        : selection.from == null
        ? s.reportRangePickStart
        : s.reportRangePickEnd;
    final quick = {
      QuickRange.last7: s.reportQuick7,
      QuickRange.last30: s.reportQuick30,
      QuickRange.quarter: s.reportQuickQuarter,
    };
    return Dialog(
      backgroundColor: c.sheetBg,
      insetPadding: EdgeInsets.symmetric(horizontal: context.screenMargin),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FreevaRadius.sheet),
      ),
      child: Semantics(
        scopesRoute: true,
        explicitChildNodes: true,
        namesRoute: true,
        label: s.reportRangeTitle,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: FreevaSpace.s2,
                runSpacing: FreevaSpace.s2,
                children: [
                  for (final e in quick.entries)
                    FreevaChip(
                      kind: FreevaChipKind.filter,
                      label: e.value,
                      selected: false,
                      onTap: () => setState(() {
                        selection = quickRange(e.key, widget.today);
                        month = _firstOf(widget.today);
                      }),
                    ),
                ],
              ),
              const SizedBox(height: FreevaSpace.s3),
              Row(
                children: [
                  FreevaIconButton(
                    icon: LucideIcons.chevronLeft,
                    label: s.reportPrevious,
                    onPressed: () => _shift(-1),
                  ),
                  Expanded(
                    child: Text(
                      DateFormat(
                        s.reportMonthTitlePattern,
                        locale,
                      ).format(month),
                      textAlign: TextAlign.center,
                      style: FreevaTypography.titleM.copyWith(
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                  FreevaIconButton(
                    icon: LucideIcons.chevronRight,
                    label: s.reportNext,
                    onPressed: _atCurrentMonth ? null : () => _shift(1),
                  ),
                ],
              ),
              const SizedBox(height: FreevaSpace.s2),
              RangeCalendar(
                month: month,
                selection: selection,
                today: widget.today,
                onTap: (day) => setState(() => selection = selection.tap(day)),
              ),
              const SizedBox(height: FreevaSpace.s3),
              Semantics(
                liveRegion: true,
                child: Text(
                  summary,
                  textAlign: TextAlign.center,
                  style: FreevaTypography.bodyS.copyWith(
                    color: c.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(height: FreevaSpace.s3),
              _Actions(
                onCancel: () => Navigator.of(context).pop(),
                onApply: selection.complete
                    ? () => Navigator.of(context).pop(selection)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Huỷ · Xem khoảng này side by side; one above the other at large text so
/// neither label is cut.
class _Actions extends StatelessWidget {
  const _Actions({required this.onCancel, required this.onApply});

  final VoidCallback onCancel;
  final VoidCallback? onApply;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cancel = FreevaButton(
      label: s.commonCancel,
      variant: FreevaButtonVariant.secondary,
      size: FreevaButtonSize.s,
      expand: true,
      onPressed: onCancel,
    );
    final apply = FreevaButton(
      label: s.reportApply,
      size: FreevaButtonSize.s,
      expand: true,
      onPressed: onApply,
    );
    if (MediaQuery.textScalerOf(context).scale(1) > 1.15) {
      return Column(
        children: [
          apply,
          const SizedBox(height: FreevaSpace.s2),
          cancel,
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: cancel),
        const SizedBox(width: FreevaSpace.s2),
        Expanded(child: apply),
      ],
    );
  }
}
