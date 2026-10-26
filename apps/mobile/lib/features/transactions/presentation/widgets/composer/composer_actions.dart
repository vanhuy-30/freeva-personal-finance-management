import 'package:flutter/material.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/widgets/freeva_dialog.dart';
import '../../../../../core/widgets/freeva_toast.dart';
import '../../../domain/transaction.dart';
import '../../viewmodels/transaction_composer.dart';
import '../transaction_naming.dart';

/// Close (asks before dropping changes) and save (toast, undo for new).
mixin ComposerActions<T extends StatefulWidget> on State<T> {
  TransactionComposer get composer;

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
    if (!await composer.save() || !mounted) return;
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
        };
}
