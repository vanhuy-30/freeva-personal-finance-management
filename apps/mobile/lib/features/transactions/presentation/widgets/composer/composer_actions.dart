import 'package:flutter/material.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/widgets/freeva_dialog.dart';
import '../../../../../core/widgets/freeva_toast.dart';
import '../../../../category_suggest/presentation/viewmodels/category_suggest_view_model.dart';
import '../../../domain/transaction.dart';
import '../../viewmodels/transaction_composer.dart';
import '../transaction_naming.dart';

/// Close (asks before dropping changes) and save (toast, undo for new).
mixin ComposerActions<T extends StatefulWidget> on State<T> {
  TransactionComposer get composer;

  /// R.1 category suggestion of this form; null when editing.
  CategorySuggestViewModel? get suggest => null;

  String kind(S s) => TransactionNaming(
    s,
    categories: const [],
    wallets: const [],
  ).kind(composer.type);

  Future<void> close() async {
    final s = S.of(context);
    if (composer.dirty) {
      final discard = await showFreevaConfirm(
        context: context,
        title: s.txDiscardTitle(kind(s)),
        message: s.txDiscardBody,
        cancelLabel: s.txKeepEditing,
        confirmLabel: s.txDiscard,
      );
      if (!discard || !mounted) return;
    }
    Navigator.of(context).pop();
  }

  Future<void> save() async {
    final s = S.of(context);
    final label = kind(s);
    final wasNew = composer.isNew;
    final ok = await composer.save();
    // Stored or queued offline: tell the server what was kept. Not queued
    // for sync, never awaited, errors ignored.
    if (ok) {
      suggest?.sendFeedback(
        type: composer.type,
        chosenCategoryId: composer.categoryId,
        merchant: composer.merchant,
      );
    }
    if (!ok || !mounted) return;
    final saved = composer.model.lastSaved;
    final model = composer.model;
    showFreevaToast(
      context,
      message: s.txSavedToast(label),
      success: true,
      actionLabel: wasNew && saved != null ? s.commonUndo : null,
      onAction: saved == null ? null : () => model.remove(saved),
    );
    Navigator.of(context).pop();
  }

  String saveLabel(S s) => !composer.isNew
      ? s.txSaveChanges
      : switch (composer.type) {
          TransactionType.expense => s.txSaveExpense,
          TransactionType.income => s.txSaveIncome,
          TransactionType.transfer => s.txSaveTransfer,
          // Only reconcile writes one; the composer never offers it.
          TransactionType.adjustment => s.txSaveChanges,
          TransactionType.debt => s.txSaveChanges,
          TransactionType.refund => s.txSaveChanges,
          TransactionType.investment => s.txSaveChanges,
        };
}
