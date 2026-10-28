import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../notifications/presentation/notification_copy.dart';
import '../../../notifications/presentation/viewmodels/notification_view_model.dart';

/// Bell target on Overview — in-app inbox from BE-P2-E05.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final NotificationViewModel _model = getIt<NotificationViewModel>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _model.loadInbox();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return ListenableBuilder(
      listenable: _model,
      builder: (context, _) {
        final items = _model.items;
        return Scaffold(
          appBar: FreevaTopBar(
            title: s.homeNotifications,
            action: items.any((item) => !item.isRead)
                ? TextButton(
                    onPressed: _model.busy ? null : _model.markAllRead,
                    child: Text(s.notifyMarkAllRead),
                  )
                : null,
          ),
          body: items.isEmpty
              ? Center(
                  child: EmptyState(
                    title: s.notificationsEmpty,
                    message: s.notificationsEmptyBody,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _model.refreshInbox,
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      context.screenMargin,
                      FreevaSpace.s2,
                      context.screenMargin,
                      FreevaSpace.s8,
                    ),
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: FreevaSpace.s2),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final c = context.colors;
                      return Material(
                        color: item.isRead ? c.bgSurface : c.bgSubtle,
                        borderRadius: BorderRadius.circular(FreevaRadius.md),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(FreevaRadius.md),
                          onTap: item.isRead || _model.busy
                              ? null
                              : () => _model.markRead(item.id),
                          child: Padding(
                            padding: const EdgeInsets.all(FreevaSpace.s4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  inboxTitle(s, item),
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: FreevaSpace.s1),
                                Text(
                                  inboxBody(s, item),
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: c.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        );
      },
    );
  }
}
