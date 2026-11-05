import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_picker_field.dart';
import '../../../../core/widgets/freeva_sheet.dart';
import '../../../notifications/domain/notification_models.dart';
import '../../../notifications/presentation/viewmodels/notification_view_model.dart';
import '../../../settings/presentation/widgets/daily_log_time_dialog.dart';

/// Default time on the board (DailyLogAsk).
const dailyLogAskDefaultTime = '21:00';

/// "Nhắc ghi chi mỗi tối?" over Tổng quan. Returns true when the reminder
/// was turned on.
Future<bool> showDailyLogAskSheet(
  BuildContext context,
  NotificationViewModel notifications,
) async {
  final on = await showFreevaSheet<bool>(
    context: context,
    scrollable: false,
    builder: (context) => DailyLogAskBody(notifications: notifications),
  );
  return on ?? false;
}

class DailyLogAskBody extends StatefulWidget {
  const DailyLogAskBody({required this.notifications, super.key});

  final NotificationViewModel notifications;

  @override
  State<DailyLogAskBody> createState() => _DailyLogAskBodyState();
}

class _DailyLogAskBodyState extends State<DailyLogAskBody> {
  String _time = dailyLogAskDefaultTime;
  bool _saving = false;

  Future<void> _pickTime() async {
    final picked = await showDailyLogTimePicker(context, initial: _time);
    if (picked != null && mounted) setState(() => _time = picked);
  }

  Future<void> _turnOn() async {
    setState(() => _saving = true);
    final n = widget.notifications;
    if (n.preferences == null) await n.loadPreferences();
    final timed = await n.setDailyLogTime(_time);
    final on = timed && await n.setKindEnabled(NotificationKind.dailyLog, true);
    if (!mounted) return;
    Navigator.of(context).pop(on);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        Center(
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.statusWarningBg,
              borderRadius: BorderRadius.circular(FreevaRadius.md),
            ),
            child: Icon(LucideIcons.bell, size: 22, color: c.statusWarning),
          ),
        ),
        const SizedBox(height: 10),
        Semantics(
          header: true,
          child: Text(
            s.dailyLogAskTitle,
            textAlign: TextAlign.center,
            style: FreevaTypography.titleL.copyWith(color: c.textPrimary),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          s.dailyLogAskBody,
          textAlign: TextAlign.center,
          style: FreevaTypography.bodyM.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: 18),
        PickerField(
          label: s.dailyLogAskTime,
          value: _time,
          chevron: false,
          leading: FieldIconTile(
            icon: LucideIcons.clock,
            background: c.statusWarningBg,
            foreground: c.statusWarning,
          ),
          onTap: _pickTime,
        ),
        const SizedBox(height: 18),
        FreevaButton(
          label: s.dailyLogAskOn,
          size: FreevaButtonSize.l,
          expand: true,
          loading: _saving,
          onPressed: _saving ? null : _turnOn,
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              minimumSize: const Size(0, FreevaSize.touch),
              padding: const EdgeInsets.symmetric(horizontal: FreevaSpace.s4),
              foregroundColor: c.textLink,
            ),
            child: Text(
              s.authLaterLink,
              style: FreevaTypography.titleM.copyWith(color: c.textLink),
            ),
          ),
        ),
      ],
    );
  }
}
