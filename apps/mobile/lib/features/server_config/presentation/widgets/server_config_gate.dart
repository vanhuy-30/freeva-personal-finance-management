import 'package:flutter/widgets.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/widgets/error_retry.dart';
import '../../domain/server_config.dart';
import '../viewmodels/server_config_view_model.dart';

/// Wrap a block that needs server config values. With no config yet it shows
/// "try again" (or nothing while the first load runs) instead of guessing numbers.
class ServerConfigGate extends StatelessWidget {
  const ServerConfigGate({required this.builder, this.model, super.key});

  final Widget Function(BuildContext context, ServerConfig config) builder;

  /// Defaults to the app-wide model; tests pass their own.
  final ServerConfigViewModel? model;

  @override
  Widget build(BuildContext context) {
    final vm = model ?? getIt<ServerConfigViewModel>();
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final config = vm.config;
        if (config != null) return builder(context, config);
        if (!vm.missing) return const SizedBox.shrink();
        final s = S.of(context);
        return ErrorRetry(
          title: s.serverConfigErrorTitle,
          message: s.serverConfigErrorMessage,
          onRetry: () => vm.refresh(force: true),
        );
      },
    );
  }
}
