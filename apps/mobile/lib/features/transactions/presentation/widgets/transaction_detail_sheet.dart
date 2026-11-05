import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/widgets/freeva_sheet.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../domain/transaction.dart';
import '../viewmodels/transaction_view_model.dart';
import '../../../../core/money/money_text.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../../installments/presentation/pages/installment_add_page.dart';
import '../../../installments/presentation/viewmodels/installment_view_model.dart';
import 'adjustment_sheet.dart';
import 'refund_delete_popup.dart';
import 'refund_sheet.dart';
import 'transaction_labels.dart';
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
      if (bundle.type == TransactionType.adjustment) {
        await showAdjustmentSheet(context, model, bundle);
        return;
      }
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
    case DetailAction.refund:
      final saved = await showRefundSheet(context, model, bundle, naming);
      if (saved == true && context.mounted) {
        showFreevaToast(context, message: s.refundSaved, success: true);
      }
    case DetailAction.installment:
      final label = naming.label(bundle);
      final installments = getIt<InstallmentViewModel>();
      await navigator.push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => InstallmentAddPage(
            model: installments,
            purchase: InstallmentPurchase(
              transactionId: bundle.id,
              accountId: bundle.legs.first.accountId,
              title: label.title,
              icon: label.icon,
              walletName: naming.wallet(bundle.legs.first.accountId),
              occurredOn: bundle.occurredOn,
              amountMinor: label.minor,
              currency: label.currency,
            ),
          ),
        ),
      );
      // The expense now carries its plan: read the list again so the row
      // does not offer it twice.
      await model.load();
    case DetailAction.openOriginal:
      final id = bundle.refundOfId;
      if (id == null) return;
      final loaded = model.rows.where((r) => r.id == id).firstOrNull;
      final original = loaded ?? await model.open(id);
      if (original != null && context.mounted) {
        await openTransactionDetail(context, model, original);
      }
    case DetailAction.delete:
      await _delete(context, model, bundle, naming);
  }
}

/// Plain delete with Hoàn tác; an expense with refunds asks first what to
/// do with them (`TxRefundDelete`) and has no undo, because restoring the
/// expense does not bring the deleted refunds back.
Future<void> _delete(
  BuildContext context,
  TransactionViewModel model,
  TransactionBundle bundle,
  TransactionNaming naming,
) async {
  final s = S.of(context);
  if (bundle.type == TransactionType.expense && bundle.refunded > BigInt.zero) {
    await _deleteWithRefunds(context, model, bundle, naming, bundle.refunded);
    return;
  }
  if (!await model.remove(bundle)) {
    // Refunds made elsewhere since the list loaded: ask, then retry.
    if (model.failure?.code == AuthError.refundExists && context.mounted) {
      await _deleteWithRefunds(context, model, bundle, naming, null);
    }
    return;
  }
  if (!context.mounted) return;
  showFreevaToast(
    context,
    message: s.txDeletedToast(naming.kind(bundle.type)),
    success: true,
    actionLabel: s.commonUndo,
    onAction: () => model.undoRemove(bundle),
  );
}

Future<void> _deleteWithRefunds(
  BuildContext context,
  TransactionViewModel model,
  TransactionBundle bundle,
  TransactionNaming naming,
  BigInt? refunded,
) async {
  final s = S.of(context);
  final locale = Localizations.localeOf(context).toString();
  final code = bundle.legs.first.currencyCode;
  final digits =
      model.currencies.where((x) => x.code == code).firstOrNull?.minorDigits ??
      0;
  // Unknown amount (stale list): read the expense again for the number
  // and its current version.
  var target = bundle;
  var amount = refunded;
  if (amount == null) {
    final fresh = await model.open(bundle.id);
    if (fresh == null || !context.mounted) return;
    target = fresh;
    amount = fresh.refunded;
  }
  final choice = await showRefundDeletePopup(
    context,
    refunded: formatMoneyText(amount, digits, locale),
  );
  if (choice == null || !context.mounted) return;
  if (!await model.remove(target, refunds: choice)) {
    final failure = model.failure;
    if (failure != null && context.mounted) {
      showFreevaToast(context, message: transactionError(s, failure));
    }
    return;
  }
  if (!context.mounted) return;
  showFreevaToast(
    context,
    message: s.txDeletedToast(naming.kind(bundle.type)),
    success: true,
  );
}
