import 'package:flutter/material.dart';
import '../../../../core/di/injection.dart';
import '../../domain/auth_repository.dart';
import '../pages/auth_page.dart';
import '../pages/lock_page.dart';
import '../viewmodels/auth_view_model.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({required this.child, super.key});
  final Widget child;
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  late final AuthViewModel _model;
  bool _covered = false;
  @override
  void initState() {
    super.initState();
    _model = getIt<AuthViewModel>();
    WidgetsBinding.instance.addObserver(this);
    _model.initialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final covered = state != AppLifecycleState.resumed;
    if (covered &&
        !(state == AppLifecycleState.inactive && _model.biometricPrompt)) {
      _model.lock();
    }
    setState(() => _covered = covered);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: _model,
      builder: (context, _) {
        if (_covered) {
          return const Scaffold(body: Center(child: Icon(Icons.lock_outline)));
        }
        if (!_model.ready) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        return switch (_model.stage) {
          AuthStage.signedOut => AuthPage(model: _model),
          AuthStage.setupPin ||
          AuthStage.locked =>
            LockPage(key: ValueKey(_model.stage), model: _model),
          AuthStage.unlocked => widget.child,
        };
      });
}
