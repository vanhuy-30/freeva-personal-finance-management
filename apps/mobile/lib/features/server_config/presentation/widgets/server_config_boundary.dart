import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/widgets/error_retry.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../viewmodels/server_config_view_model.dart';
import 'server_config_listener.dart';

/// MOB-P5-001: the app runs only with server config (public config before
/// sign-in), so screens read [ServerConfigViewModel.requireLimits] instead of
/// guessing numbers. Without a cached or fetched copy it waits, and after a
/// failed load shows one "try again" screen.
class ServerConfigBoundary extends StatefulWidget {
  const ServerConfigBoundary({
    required this.child,
    this.auth,
    this.model,
    super.key,
  });

  final Widget child;

  /// Default to the app-wide instances; tests pass their own.
  final AuthViewModel? auth;
  final ServerConfigViewModel? model;

  @override
  State<ServerConfigBoundary> createState() => _ServerConfigBoundaryState();
}

class _ServerConfigBoundaryState extends State<ServerConfigBoundary> {
  late final AuthViewModel _auth = widget.auth ?? getIt<AuthViewModel>();
  late final ServerConfigViewModel _config =
      widget.model ?? getIt<ServerConfigViewModel>();

  @override
  void initState() {
    super.initState();
    _auth.addListener(_changed);
    _config.addListener(_changed);
  }

  @override
  void dispose() {
    _auth.removeListener(_changed);
    _config.removeListener(_changed);
    super.dispose();
  }

  /// Auth may notify while the routed screen below is building; this widget
  /// sits above it, so rebuild after that frame instead of mid-build.
  void _changed() {
    if (!mounted) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _config;
    if (config.limits != null) return widget.child;
    if (!config.missing && (config.loading || config.config == null)) {
      return const Material(child: Center(child: CircularProgressIndicator()));
    }
    final s = S.of(context);
    return Material(
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ErrorRetry(
              title: s.serverConfigErrorTitle,
              message: s.serverConfigErrorMessage,
              onRetry: () => config.refresh(
                force: true,
                signedIn: hasSession(_auth.stage),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
