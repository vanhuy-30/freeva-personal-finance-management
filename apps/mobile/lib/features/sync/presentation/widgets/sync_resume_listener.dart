import 'package:flutter/widgets.dart';

import '../../../../core/di/injection.dart';
import '../viewmodels/sync_view_model.dart';

class SyncResumeListener extends StatefulWidget {
  const SyncResumeListener({required this.child, super.key});

  final Widget child;

  @override
  State<SyncResumeListener> createState() => _SyncResumeListenerState();
}

class _SyncResumeListenerState extends State<SyncResumeListener>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      getIt<SyncViewModel>().onResume();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
