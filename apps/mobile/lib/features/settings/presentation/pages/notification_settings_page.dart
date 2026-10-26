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
import '../viewmodels/settings_view_model.dart';

/// Thông báo. Only "Máy mới đăng nhập" works today; the rest show "Sắp có"
/// instead of a switch that would do nothing (they need push notifications
/// and budgets).
class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = getIt<SettingsViewModel>();
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final s = S.of(context);
        final margin = context.screenMargin;
        Widget soon(IconData icon, String title, String sub) => SettingsRow(
          icon: icon,
          title: title,
          subtitle: sub,
          value: s.meSoon,
          chevron: false,
        );
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
              SettingsGroup(
                title: s.notifyReminders,
                children: [
                  soon(
                    LucideIcons.pencilLine,
                    s.notifyRecord,
                    s.notifyRecordSub,
                  ),
                  soon(LucideIcons.chartPie, s.notifyDigest, s.notifyDigestSub),
                ],
              ),
              SettingsGroup(
                title: s.notifyAlerts,
                children: [
                  soon(
                    LucideIcons.piggyBank,
                    s.notifyBudget,
                    s.notifyBudgetSub,
                  ),
                  soon(LucideIcons.creditCard, s.notifyCard, s.notifyCardSub),
                  SettingsRow.toggle(
                    icon: LucideIcons.smartphone,
                    title: s.notifySession,
                    subtitle: s.notifySessionSub,
                    on: settings.sessionAlertsEnabled,
                    onChanged: (value) {
                      if (!settings.loading) {
                        settings.setSessionAlertsEnabled(value);
                      }
                    },
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
