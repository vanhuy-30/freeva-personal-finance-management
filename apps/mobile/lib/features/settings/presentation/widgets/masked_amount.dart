import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../viewmodels/settings_view_model.dart';

class MaskedAmount extends StatelessWidget {
  const MaskedAmount({
    required this.shown,
    required this.hidden,
    this.style,
    super.key,
  });

  final String shown;
  final String hidden;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    if (!getIt.isRegistered<SettingsViewModel>()) {
      return Text(shown, style: style);
    }
    final settings = getIt<SettingsViewModel>();
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) =>
          Text(settings.balancesHidden ? hidden : shown, style: style),
    );
  }
}
