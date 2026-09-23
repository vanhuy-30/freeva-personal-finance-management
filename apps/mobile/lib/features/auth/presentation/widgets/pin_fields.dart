import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/l10n/generated/app_localizations.dart';

class PinFields extends StatelessWidget {
  const PinFields(
      {required this.pin,
      required this.confirmation,
      required this.setup,
      required this.enabled,
      super.key});
  final TextEditingController pin, confirmation;
  final bool setup, enabled;
  @override
  Widget build(BuildContext context) => Column(children: [
        _field(pin, S.of(context).authPin),
        if (setup) _field(confirmation, S.of(context).authConfirmPin),
      ]);
  Widget _field(TextEditingController controller, String label) => TextField(
        controller: controller,
        enabled: enabled,
        obscureText: true,
        keyboardType: TextInputType.number,
        maxLength: 6,
        enableSuggestions: false,
        autocorrect: false,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(labelText: label),
      );
}
