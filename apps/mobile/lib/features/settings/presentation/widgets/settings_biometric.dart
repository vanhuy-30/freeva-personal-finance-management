import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../auth/domain/auth_repository.dart';
import '../viewmodels/settings_view_model.dart';

class SettingsBiometric extends StatefulWidget {
  const SettingsBiometric({required this.model, super.key});

  final SettingsViewModel model;

  @override
  State<SettingsBiometric> createState() => _SettingsBiometricState();
}

class _SettingsBiometricState extends State<SettingsBiometric> {
  @override
  void initState() {
    super.initState();
    widget.model.refreshBiometrics();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final model = widget.model;
    final canChange =
        !model.biometricBusy &&
        (model.biometricHardware || model.biometricEnabled);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          s.settingsPermissions,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(s.settingsBiometric),
          subtitle: Text(_status(s, model)),
          value: model.biometricEnabled,
          onChanged: canChange
              ? (value) {
                  if (value && !model.biometricHardware) return;
                  model.setBiometricEnabled(value, s.settingsBiometricReason);
                }
              : null,
        ),
      ],
    );
  }

  String _status(S s, SettingsViewModel model) {
    final failure = model.biometricFailure;
    if (failure?.code == AuthError.invalidInput) return s.settingsBiometricPin;
    if (failure != null) return s.settingsBiometricFailed;
    if (!model.biometricHardware) return s.settingsBiometricUnavailable;
    return model.biometricEnabled
        ? s.settingsBiometricOn
        : s.settingsBiometricOff;
  }
}
