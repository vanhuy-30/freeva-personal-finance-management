import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../settings/presentation/viewmodels/settings_view_model.dart';

class OverviewBalanceToggle extends StatelessWidget {
  const OverviewBalanceToggle({super.key});

  @override
  Widget build(BuildContext context) {
    if (!getIt.isRegistered<SettingsViewModel>()) {
      return const SizedBox.shrink();
    }
    final settings = getIt<SettingsViewModel>();
    final s = S.of(context);
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => IconButton(
        tooltip: settings.balancesHidden ? s.balanceShow : s.balanceHide,
        onPressed: () => settings.setBalancesHidden(!settings.balancesHidden),
        icon: Icon(
          settings.balancesHidden ? LucideIcons.eyeOff : LucideIcons.eye,
        ),
      ),
    );
  }
}
