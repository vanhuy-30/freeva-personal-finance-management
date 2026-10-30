import 'package:flutter/widgets.dart';

import '../../../../core/di/injection.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../domain/push_registrar.dart';

/// Keeps the FCM token registered while signed in and drops it on sign-out.
/// Never asks for permission; that happens when the user turns a kind on.
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _auth.addListener(_authChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncIfSignedIn());
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
      getIt<PushRegistrar>().clear();
    } else if (previous == AuthStage.signedOut ||
        _stage == AuthStage.unlocked) {
      _syncIfSignedIn();
    }
  }

  void _syncIfSignedIn() {
    if (_auth.stage == AuthStage.unlocked) getIt<PushRegistrar>().sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _syncIfSignedIn();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
