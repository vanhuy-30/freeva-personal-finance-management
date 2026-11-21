import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../viewmodels/investment_view_model.dart';
import 'matured_deposit_sheets.dart';

/// Looks for matured savings deposits each time the unlocked app opens or
/// resumes. A deposit that came from a wallet is paid back into it and the
/// user is told; one held before the app asks where the money goes (a wallet
/// or a new deposit), once per launch.
class MaturedDepositListener extends StatefulWidget {
  const MaturedDepositListener({required this.child, super.key});

  final Widget child;

  @override
  State<MaturedDepositListener> createState() => _MaturedDepositListenerState();
}

class _MaturedDepositListenerState extends State<MaturedDepositListener>
    with WidgetsBindingObserver {
  late final AuthViewModel _auth = getIt<AuthViewModel>();
  late AuthStage _stage = _auth.stage;
  final Set<String> _asked = {};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _auth.addListener(_authChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_check()));
  }

  @override
  void dispose() {
    _auth.removeListener(_authChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _authChanged() {
    if (_auth.stage == _stage) return;
    _stage = _auth.stage;
    if (_stage == AuthStage.signedOut) _asked.clear();
    if (_stage == AuthStage.unlocked) unawaited(_check());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_check());
  }

  BuildContext? get _overlayContext =>
      appRouter.routerDelegate.navigatorKey.currentContext;

  Future<void> _check() async {
    if (_busy || _auth.stage != AuthStage.unlocked) return;
    _busy = true;
    try {
      final model = getIt<InvestmentViewModel>();
      await model.load();
      if (!model.loaded) return;
      final payouts = await model.settleMatured();
      var context = _overlayContext;
      if (payouts.isNotEmpty && context != null && context.mounted) {
        await showMaturedPaidSheet(context, model, payouts);
      }
      for (final deposit in model.maturedAwaitingChoice) {
        if (!_asked.add(deposit.id) || _auth.stage != AuthStage.unlocked) {
          continue;
        }
        context = _overlayContext;
        if (context == null || !context.mounted) break;
        await showMaturedChoiceSheet(context, model, deposit);
      }
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
