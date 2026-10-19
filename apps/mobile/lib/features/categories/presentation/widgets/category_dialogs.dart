import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';

Future<void> showCategoryNotice(BuildContext context, String message) {
  final s = S.of(context);
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.transactionCancel),
        ),
      ],
    ),
  );
}

Future<bool> confirmCategoryArchive(
  BuildContext context, {
  required bool restore,
}) async {
  final s = S.of(context);
  final label = restore ? s.categoryRestore : s.categoryHide;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(label),
      content: Text(s.categoryHideExplanation),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(s.transactionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(label),
        ),
      ],
    ),
  );
  return confirmed == true;
}
