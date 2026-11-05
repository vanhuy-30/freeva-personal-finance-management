import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../domain/push_registrar.dart';

/// Keeps the FCM token registered while signed in and drops it on sign-out.
/// Never asks for permission; that happens when the user turns a kind on.
/// A tapped push opens its screen ([routeForOpenedKind]) once unlocked.
class PushRegistrationListener extends StatefulWidget {
  const PushRegistrationListener({required this.child, super.key});

  final Widget child;

  @override
  State<PushRegistrationListener> createState() =>
      _PushRegistrationListenerState();
}

class _PushRegistrationListenerState extends State<PushRegistrationListener>
    with WidgetsBindingObserver {
  late final AuthViewModel _auth = getIt<AuthViewModel>();
  late AuthStage _stage = _auth.stage;
  StreamSubscription<String>? _opened;
  String? _pendingRoute;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _auth.addListener(_authChanged);
    _opened = getIt<PushRegistrar>().openedKinds().listen((kind) {
      _pendingRoute = routeForOpenedKind(kind);
      _openPending();
    }, onError: (Object _) {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncIfSignedIn());
  }

  @override
  void dispose() {
    unawaited(_opened?.cancel());
    _auth.removeListener(_authChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _authChanged() {
    if (_auth.stage == _stage) return;
    final previous = _stage;
    _stage = _auth.stage;
    if (_stage == AuthStage.signedOut) {
      _pendingRoute = null;
      getIt<PushRegistrar>().clear();
    } else if (previous == AuthStage.signedOut ||
        _stage == AuthStage.unlocked) {
      _syncIfSignedIn();
    }
  }

  void _syncIfSignedIn() {
    if (_auth.stage != AuthStage.unlocked) return;
    getIt<PushRegistrar>().sync();
    _openPending();
  }

  /// Waits for the unlocked app (PIN, splash) before leaving the current screen.
  void _openPending() {
    final route = _pendingRoute;
    if (route == null || _auth.stage != AuthStage.unlocked) return;
    _pendingRoute = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) appRouter.push(route);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _syncIfSignedIn();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
