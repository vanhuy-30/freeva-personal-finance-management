import 'package:flutter/material.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../settings/presentation/viewmodels/settings_view_model.dart';
import '../../../domain/transaction.dart';
import '../../viewmodels/transaction_composer.dart';
import 'category_picker_sheet.dart';
import 'date_picker_sheet.dart';
import 'rate_dialog.dart';
import 'tag_picker_sheet.dart';
import 'wallet_picker_sheet.dart';

/// Opens each picker for [composer] and writes the result back.
class ComposerPickers {
  const ComposerPickers(this.context, this.composer);

  final BuildContext context;
  final TransactionComposer composer;

  bool get _hide =>
      getIt.isRegistered<SettingsViewModel>() &&
      getIt<SettingsViewModel>().balancesHidden;

  Future<void> category() async {
    final model = composer.model;
    final fitting = composer.fitting;
    final ids = fitting.map((c) => c.id).toSet();
    final id = await showCategoryPicker(
      context,
      categories: fitting,
      frequent: [
        for (final c in model.recentCategories)
          if (ids.contains(c.id)) c,
      ],
      selected: composer.categoryId,
    );
    if (id != null) composer.pickCategory(id);
  }

  Future<void> wallet({bool counter = false}) async {
    final s = S.of(context);
    final id = await showWalletPicker(
      context,
      title: s.txPickWallet,
      subtitle: counter || composer.transfer
          ? null
          : composer.type == TransactionType.income
          ? s.txWalletSubIncome
          : s.txWalletSubExpense,
      wallets: [
        for (final w in composer.model.wallets)
          if (!counter || w.id != composer.accountId) w,
      ],
      selected: counter ? composer.counterAccountId : composer.accountId,
      digitsOf: composer.digitsOf,
      hideBalances: _hide,
    );
    if (id == null) return;
    counter ? composer.pickCounter(id) : composer.pickAccount(id);
  }

  Future<void> date() async {
    final today = composer.model.today() ?? composer.occurredOn;
    final value = await showDatePickerSheet(
      context,
      value: composer.occurredOn,
      today: today,
    );
    if (value != null) composer.setDate(value);
  }

  Future<void> tags() async {
    final ids = await showTagPicker(
      context,
      model: composer.model,
      selected: composer.tagIds,
    );
    if (ids != null) composer.setTags(ids);
  }

  Future<void> rate() async {
    final from = composer.source?.draft.currency ?? '';
    final to = composer.destination?.draft.currency ?? '';
    final value = await showRateDialog(
      context,
      value: composer.rate,
      label: '1 $from = ? $to',
    );
    if (value != null) composer.setRate(value);
  }
}
