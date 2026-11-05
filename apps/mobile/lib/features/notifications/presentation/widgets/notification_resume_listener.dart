import 'package:flutter/widgets.dart';

import '../../../../core/di/injection.dart';
import '../viewmodels/notification_view_model.dart';

/// Evaluates due in-app notifications once at mount and on every app resume.
class NotificationResumeListener extends StatefulWidget {
  const NotificationResumeListener({required this.child, super.key});

  final Widget child;

  @override
  State<NotificationResumeListener> createState() =>
      _NotificationResumeListenerState();
}

class _NotificationResumeListenerState extends State<NotificationResumeListener>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getIt<NotificationViewModel>().evaluateQuietly();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      getIt<NotificationViewModel>().evaluateQuietly();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
