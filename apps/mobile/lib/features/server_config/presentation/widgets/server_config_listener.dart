import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../../core/di/injection.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../viewmodels/server_config_view_model.dart';

/// Stages with a signed-in session that can call the API and need config.
bool hasSession(AuthStage stage) =>
    stage == AuthStage.setup || stage == AuthStage.unlocked;

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
    // Auth can change while widgets build; touch config after this frame so
    // its listeners (ServerConfigBoundary) are not marked dirty mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_stage == AuthStage.signedOut) {
        unawaited(_config.clear());
      } else if (hasSession(_stage)) {
        // Onboarding (setup) already needs config numbers (MOB-P5-001).
        _refresh(force: previous == AuthStage.signedOut);
      }
    });
  }

  void _refresh({bool force = false}) {
    if (!hasSession(_auth.stage)) return;
    unawaited(_config.refresh(force: force));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
