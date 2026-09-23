import 'package:flutter/material.dart';
import '../widgets/pin_fields.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../domain/auth_repository.dart';
import '../viewmodels/auth_view_model.dart';
import '../widgets/auth_message.dart';

class LockPage extends StatefulWidget {
  const LockPage({required this.model, super.key});
  final AuthViewModel model;
  @override
  State<LockPage> createState() => _LockPageState();
}

class _LockPageState extends State<LockPage> {
  final _pin = TextEditingController();
  final _confirmation = TextEditingController();
  bool _biometric = false;
  @override
  void dispose() {
    _pin.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    final s = S.of(context);
    final setup = model.stage == AuthStage.setupPin;
    return Scaffold(
        appBar: AppBar(title: Text(setup ? s.authSetupPin : s.authLocked)),
        body: SafeArea(
            child: Center(
                child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Icon(Icons.lock_outline, size: 56),
                              Text(s.authPinHelp),
                              PinFields(
                                  pin: _pin,
                                  confirmation: _confirmation,
                                  setup: setup,
                                  enabled: !model.loading),
                              if (setup && model.biometricAvailable)
                                SwitchListTile(
                                    title: Text(s.authEnableBiometric),
                                    value: _biometric,
                                    onChanged: model.loading
                                        ? null
                                        : (value) =>
                                            setState(() => _biometric = value)),
                              AuthMessage(model: model),
                              FilledButton(
                                  onPressed: model.loading
                                      ? null
                                      : () async {
                                          final operation = setup
                                              ? model.setupPin(
                                                  _pin.text,
                                                  _confirmation.text,
                                                  _biometric,
                                                  s.authBiometricReason)
                                              : model.unlockPin(_pin.text);
                                          _pin.clear();
                                          _confirmation.clear();
                                          await operation;
                                        },
                                  child: Text(
                                      setup ? s.authSetupPin : s.authUnlock)),
                              if (!setup && model.biometricAvailable)
                                TextButton(
                                    onPressed: model.loading
                                        ? null
                                        : () => model.unlockBiometric(
                                            s.authBiometricReason),
                                    child: Text(s.authUseBiometric)),
                              TextButton(
                                  onPressed:
                                      model.loading ? null : model.forgetDevice,
                                  child: Text(s.authForgetDevice)),
                              Text(s.authForgetHelp,
                                  style: Theme.of(context).textTheme.bodySmall),
                              if (model.loading)
                                const LinearProgressIndicator(),
                            ]))))));
  }
}
