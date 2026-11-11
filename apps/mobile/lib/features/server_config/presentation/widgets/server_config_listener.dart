import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../../core/di/injection.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../viewmodels/server_config_view_model.dart';

/// Loads server flags and config when the app unlocks and when it resumes
/// (at most hourly), and forgets them on sign-out.
class ServerConfigListener extends StatefulWidget {
  const ServerConfigListener({required this.child, super.key});

  final Widget child;

  @override
  State<ServerConfigListener> createState() => _ServerConfigListenerState();
}

class _ServerConfigListenerState extends State<ServerConfigListener>
    with WidgetsBindingObserver {
  late final AuthViewModel _auth = getIt<AuthViewModel>();
  late final ServerConfigViewModel _config = getIt<ServerConfigViewModel>();
  late AuthStage _stage = _auth.stage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _auth.addListener(_authChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh(force: true));
  }

  @override
  void dispose() {
    _auth.removeListener(_authChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _authChanged() {
    if (_auth.stage == _stage) return;
    final previous = _stage;
    _stage = _auth.stage;
    if (_stage == AuthStage.signedOut) {
      unawaited(_config.clear());
    } else if (_stage == AuthStage.unlocked) {
      _refresh(
        force: previous == AuthStage.signedOut || previous == AuthStage.setup,
      );
    }
  }

  void _refresh({bool force = false}) {
    if (_auth.stage != AuthStage.unlocked) return;
    unawaited(_config.refresh(force: force));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
