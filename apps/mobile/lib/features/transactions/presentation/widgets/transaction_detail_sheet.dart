import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/widgets/freeva_sheet.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../domain/transaction.dart';
import '../viewmodels/transaction_view_model.dart';
import 'transaction_editor.dart';
import 'transaction_naming.dart';
import 'transaction_detail_body.dart';

/// Opens the detail sheet of [bundle]: Sửa · Sao chép · Xoá (with Hoàn tác).
Future<void> openTransactionDetail(
  BuildContext context,
  TransactionViewModel model,
  TransactionBundle bundle,
) async {
  final s = S.of(context);
  final naming = TransactionNaming(
    s,
    categories: model.categories,
    wallets: model.wallets,
    tags: model.tags,
  );
  final action = await showFreevaSheet<DetailAction>(
    context: context,
    builder: (_) =>
        TransactionDetailBody(model: model, bundle: bundle, naming: naming),
  );
  if (!context.mounted || action == null) return;
  final navigator = Navigator.of(context, rootNavigator: true);
  switch (action) {
    case DetailAction.edit:
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) =>
              TransactionEditor(model: model, transactionId: bundle.id),
        ),
      );
    case DetailAction.copy:
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) =>
              TransactionEditor(model: model, initial: bundle, copy: true),
        ),
      );
    case DetailAction.delete:
      if (!await model.remove(bundle) || !context.mounted) return;
      showFreevaToast(
        context,
        message: s.txDeletedToast(naming.kind(bundle.type)),
        success: true,
        actionLabel: s.commonUndo,
        onAction: () => model.undoRemove(bundle),
      );
  }
}
