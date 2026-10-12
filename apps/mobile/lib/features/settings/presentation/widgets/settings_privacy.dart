import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../viewmodels/settings_view_model.dart';

class SettingsPrivacy extends StatelessWidget {
  const SettingsPrivacy({required this.model, super.key});

  final SettingsViewModel model;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          s.settingsPrivacyControls,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(s.settingsHideBalances),
          subtitle: Text(s.settingsHideBalancesHelp),
          value: model.balancesHidden,
          onChanged: model.loading ? null : model.setBalancesHidden,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(s.settingsSessionAlerts),
          subtitle: Text(s.settingsSessionAlertsHelp),
          value: model.sessionAlertsEnabled,
          onChanged: model.loading ? null : model.setSessionAlertsEnabled,
        ),
      ],
    );
  }
}
