import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../../core/widgets/settings_group.dart';
import '../../../../core/widgets/settings_row.dart';
import '../../../notifications/domain/notification_models.dart';
import '../../../notifications/presentation/notification_copy.dart';
import '../../../notifications/presentation/viewmodels/notification_view_model.dart';
import '../viewmodels/settings_view_model.dart';
import '../widgets/lead_settings_group.dart';

/// Notification toggles. Session alerts stay on-device; other kinds use the API.
class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  late final NotificationViewModel _notifications =
      getIt<NotificationViewModel>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifications.loadPreferences();
    });
  }

  Future<void> _pickQuietWindow(S s, NotificationPreferences prefs) async {
    final start = await showTimePicker(
      context: context,
      initialTime: _hm(prefs.quietStart) ?? const TimeOfDay(hour: 22, minute: 0),
      helpText: s.notifyQuietStart,
    );
    if (!mounted || start == null) return;
    final end = await showTimePicker(
      context: context,
      initialTime: _hm(prefs.quietEnd) ?? const TimeOfDay(hour: 7, minute: 0),
      helpText: s.notifyQuietEnd,
    );
    if (!mounted || end == null) return;
    final startText = _format(start);
    final endText = _format(end);
    if (startText == endText) return;
    await _notifications.setQuietHours(
      enabled: true,
      quietStart: startText,
      quietEnd: endText,
    );
  }

  TimeOfDay? _hm(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _format(TimeOfDay value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final settings = getIt<SettingsViewModel>();
    return ListenableBuilder(
      listenable: Listenable.merge([settings, _notifications]),
      builder: (context, _) {
        final s = S.of(context);
        final margin = context.screenMargin;
        final c = context.colors;
        const rowHeight = 60.0;
        final prefs = _notifications.preferences;

        Widget soon(IconData icon, NotificationKind kind) => SettingsRow(
          icon: icon,
          title: notificationKindTitle(s, kind),
          subtitle: notificationKindSubtitle(s, kind),
          value: s.meSoon,
          chevron: false,
          minHeight: rowHeight,
        );

        Widget kindToggle(IconData icon, NotificationKind kind, {(Color, Color)? tint}) {
          final toggle = prefs?.toggle(kind);
          if (toggle == null || !toggle.available || toggle.managedLocally) {
            return soon(icon, kind);
          }
          return SettingsRow.toggle(
            icon: icon,
            title: notificationKindTitle(s, kind),
            subtitle: notificationKindSubtitle(s, kind),
            minHeight: rowHeight,
            tint: tint,
            on: toggle.enabled,
            onChanged: (value) {
              if (!_notifications.busy) {
                _notifications.setKindEnabled(kind, value);
              }
            },
          );
        }

        return Scaffold(
          appBar: FreevaTopBar(
            title: s.meNotifications,
            onLeading: () => context.popOrGo('/me'),
          ),
          body: ListView(
            padding: EdgeInsets.fromLTRB(
              margin,
              FreevaSpace.s2,
              margin,
              FreevaSpace.s8,
            ),
            children: [
              LeadSettingsGroup(
                title: s.notifyReminders,
                children: [
                  kindToggle(LucideIcons.repeat, NotificationKind.recurring),
                  soon(LucideIcons.target, NotificationKind.goal),
                  soon(LucideIcons.calendarCheck, NotificationKind.monthReview),
                ],
              ),
              SettingsGroup(
                title: s.notifyAlerts,
                children: [
                  kindToggle(
                    LucideIcons.triangleAlert,
                    NotificationKind.budget,
                    tint: (c.statusWarningBg, c.statusWarning),
                  ),
                  soon(LucideIcons.handCoins, NotificationKind.debt),
                  soon(LucideIcons.creditCard, NotificationKind.card),
                  soon(LucideIcons.sparkles, NotificationKind.insight),
                  SettingsRow.toggle(
                    icon: LucideIcons.smartphone,
                    title: s.notifySession,
                    subtitle: s.notifySessionSubAlways,
                    minHeight: rowHeight,
                    on: settings.sessionAlertsEnabled,
                    onChanged: (value) {
                      if (!settings.loading) {
                        settings.setSessionAlertsEnabled(value);
                      }
                    },
                  ),
                ],
              ),
              SettingsGroup(
                title: s.notifyQuietTitle,
                children: [
                  SettingsRow.toggle(
                    icon: LucideIcons.moon,
                    title: s.notifyQuietHours,
                    subtitle: prefs == null
                        ? null
                        : s.notifyQuietWindow(prefs.quietStart, prefs.quietEnd),
                    minHeight: rowHeight,
                    on: prefs?.quietHoursEnabled ?? false,
                    onChanged: (value) {
                      if (prefs == null || _notifications.busy) return;
                      _notifications.setQuietHours(enabled: value);
                    },
                  ),
                  if (prefs != null && prefs.quietHoursEnabled)
                    SettingsRow(
                      icon: LucideIcons.clock,
                      title: s.notifyQuietEdit,
                      value: s.notifyQuietWindow(
                        prefs.quietStart,
                        prefs.quietEnd,
                      ),
                      minHeight: rowHeight,
                      onTap: _notifications.busy
                          ? null
                          : () => _pickQuietWindow(s, prefs),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
