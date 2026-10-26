import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/freeva_top_bar.dart';

/// Bell target on Overview. Empty until the notification centre exists
/// (`BE-P2-E05`); kept so the approved bell is not dropped.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: FreevaTopBar(title: s.homeNotifications),
      body: Center(
        child: EmptyState(
          title: s.notificationsEmpty,
          message: s.notificationsEmptyBody,
        ),
      ),
    );
  }
}
