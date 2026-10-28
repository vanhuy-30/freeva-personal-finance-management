import 'package:flutter/widgets.dart';

import '../../../../core/di/injection.dart';
import '../viewmodels/recurring_view_model.dart';

/// Runs due recurring posts once at mount and again on every app resume.
class RecurringResumeListener extends StatefulWidget {
  const RecurringResumeListener({required this.child, super.key});

  final Widget child;

  @override
  State<RecurringResumeListener> createState() =>
      _RecurringResumeListenerState();
}

class _RecurringResumeListenerState extends State<RecurringResumeListener>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getIt<RecurringViewModel>().runQuietly();
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
      getIt<RecurringViewModel>().runQuietly();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
