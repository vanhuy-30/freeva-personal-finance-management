import 'package:flutter/material.dart';

import '../viewmodels/auth_view_model.dart';
import '../widgets/pin_setup_flow.dart';
import '../widgets/verify_email_step.dart';

/// First run after sign-up: confirm email, then an optional PIN. Leaving
/// either step is always allowed; [AuthViewModel.finishSetup] opens the app.
class SetupPage extends StatefulWidget {
  const SetupPage({required this.model, super.key});

  final AuthViewModel model;

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  var _pinStep = false;

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    if (!_pinStep) {
      return VerifyEmailStep(
        model: model,
        onDone: () => setState(() => _pinStep = true),
      );
    }
    return PinSetupFlow(
      model: model,
      onSkip: model.finishSetup,
      onBack: () => setState(() => _pinStep = false),
    );
  }
}
