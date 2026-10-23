import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../viewmodels/settings_view_model.dart';

/// Rebuilds with the "ẩn số dư" setting. It hides balances only, never
/// income, expense or transaction amounts.
class BalancesHiddenBuilder extends StatelessWidget {
  const BalancesHiddenBuilder({required this.builder, super.key});

  final Widget Function(BuildContext context, bool hidden) builder;

  @override
  Widget build(BuildContext context) {
    if (!getIt.isRegistered<SettingsViewModel>()) {
      return builder(context, false);
    }
    final settings = getIt<SettingsViewModel>();
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => builder(context, settings.balancesHidden),
    );
  }
}
