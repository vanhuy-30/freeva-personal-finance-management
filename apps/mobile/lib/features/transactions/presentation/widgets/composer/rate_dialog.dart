import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/widgets/freeva_dialog_input.dart';

/// Edit the exchange rate (destination units per 1 source unit).
Future<String?> showRateDialog(
  BuildContext context, {
  required String value,
  required String label,
}) => showFreevaInputDialog(
  context: context,
  title: S.of(context).txRateTitle,
  label: label,
  initial: value,
  keyboardType: const TextInputType.numberWithOptions(decimal: true),
  formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
);
