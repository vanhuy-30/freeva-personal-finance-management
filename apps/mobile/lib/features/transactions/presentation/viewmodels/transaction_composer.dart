import 'package:flutter/foundation.dart';

import '../../../categories/domain/finance_category.dart';
import '../../../wallets/domain/wallet.dart';
import '../../domain/transaction.dart';
import '../../domain/transaction_money.dart';
import 'transaction_view_model.dart';

/// State of one record/edit form. The amount is typed on Freeva's keypad as
/// minor units (ATM style: "1","0","0" on a 2-digit currency is 1,00), so no
/// floating point and no decimal key. Saving builds the same
/// [TransactionDraft] the domain rules validate (balanced transfer legs,
/// rate + quote time).
class TransactionComposer extends ChangeNotifier {
  TransactionComposer(
    this.model, {
    TransactionBundle? existing,
    this.copy = false,
    TransactionType? initialType,
    String? fromAccountId,
    String? toAccountId,
  }) : existing = copy ? null : existing {
    final from = existing;
    type = from?.type ?? initialType ?? TransactionType.expense;
    // Opened from a wallet ("Ghi từ ví này", "Trả thẻ"): keep that wallet.
    final source = wallet(fromAccountId)?.id;
    _accountTouched = source != null;
    accountId =
        from?.legs.first.accountId ?? source ?? model.preferredAccountId();
    counterAccountId = from != null && from.legs.length > 1
        ? from.legs[1].accountId
        : wallet(toAccountId)?.id;
    if (from == null &&
        counterAccountId != null &&
        accountId == counterAccountId) {
      accountId = model.wallets
          .where((w) => !w.archived && w.id != counterAccountId)
          .firstOrNull
          ?.id;
    }
    categoryId = from?.categoryId ?? _defaultCategory();
    // A copy is a new transaction today (C1.5).
    occurredOn = (copy ? null : from?.occurredOn) ?? model.today() ?? '';
    notes = from?.notes ?? '';
    merchant = from?.merchant ?? '';
    tagIds = List.of(from?.tagIds ?? const []);
    rate = from?.fx?.rate ?? '';
    _rateSeed = rate;
    quotedAt = from?.fx?.quotedAt;
    amount = from?.legs.first.amountMinor.abs() ?? BigInt.zero;
    clientIds = from != null && !copy
        ? from.legs.map((l) => l.clientId).toList()
        : [model.newClientId(), model.newClientId()];
    _initial = _snapshot();
    model.addListener(_syncDefaults);
  }

  /// Max digits typed on the keypad.
  static const maxDigits = 13;

  final TransactionViewModel model;
  final TransactionBundle? existing;
  final bool copy;

  late TransactionType type;
  late BigInt amount;
  String? accountId;
  String? counterAccountId;
  String? categoryId;
  late String occurredOn;
  late String notes;
  late String merchant;
  late List<String> tagIds;
  late String rate;
  String? quotedAt;
  late List<String> clientIds;
  bool saving = false;
  bool invalid = false;
  bool _accountTouched = false;
  bool _categoryTouched = false;
  late String _rateSeed;
  late String _initial;

  bool get isNew => existing == null;
  bool get dirty => _snapshot() != _initial;
  bool get transfer => type == TransactionType.transfer;

  Wallet? wallet(String? id) =>
      model.wallets.where((w) => w.id == id).firstOrNull;
  Wallet? get source => wallet(accountId);
  Wallet? get destination => wallet(counterAccountId);
  int digitsOf(String? code) =>
      model.currencies
          .where((c) => c.code == code)
          .map((c) => c.minorDigits)
          .firstOrNull ??
      0;
  int get digits => digitsOf(source?.draft.currency ?? model.profileCurrency);
  String get currency => source?.draft.currency ?? model.profileCurrency;
  bool get cross =>
      transfer &&
      destination != null &&
      source != null &&
      destination!.draft.currency != source!.draft.currency;

  /// What the destination wallet receives; null while the rate is missing
  /// or would need a fractional minor unit.
  BigInt? get received {
    if (!transfer || destination == null) return null;
    if (!cross) return amount;
    if (amount == BigInt.zero) return BigInt.zero;
    return convertedMinor(
      -amount,
      rate,
      digits,
      digitsOf(destination!.draft.currency),
    );
  }

  FinanceCategory? get category =>
      model.categories.where((c) => c.id == categoryId).firstOrNull;

  /// Categories that fit the current type (expense or income).
  List<FinanceCategory> get fitting => [
    for (final c in model.categories)
      if (!c.archived && c.kind.fits(type == TransactionType.income)) c,
  ];

  /// Three quick chips: recent fitting categories, keeping the chosen one.
  List<FinanceCategory> get quick {
    final ids = fitting.map((c) => c.id).toSet();
    final picks = [
      if (category != null) category!,
      for (final c in model.recentCategories)
        if (ids.contains(c.id) && c.id != categoryId) c,
    ];
    return picks.take(3).toList();
  }

  // Keypad -----------------------------------------------------------------

  void typeKeys(String keys) {
    final next = amount.toString() == '0'
        ? keys.replaceFirst(RegExp(r'^0+'), '')
        : '$amount$keys';
    if (next.isEmpty || next.length > maxDigits) return;
    amount = BigInt.parse(next);
    invalid = false;
    notifyListeners();
  }

  void backspace() {
    amount = amount ~/ BigInt.from(10);
    notifyListeners();
  }

  // Fields -----------------------------------------------------------------

  void setType(TransactionType value) {
    if (!isNew || value == type) return;
    type = value;
    if (!transfer &&
        !(category?.kind.fits(value == TransactionType.income) ?? true)) {
      categoryId = null;
    }
    categoryId ??= transfer ? null : _defaultCategory();
    notifyListeners();
  }

  void pickCategory(String id) {
    categoryId = id;
    _categoryTouched = true;
    notifyListeners();
  }

  void pickAccount(String id) {
    accountId = id;
    _accountTouched = true;
    if (counterAccountId == id) counterAccountId = null;
    notifyListeners();
  }

  void pickCounter(String id) {
    counterAccountId = id;
    notifyListeners();
  }

  void swap() {
    final from = accountId;
    accountId = counterAccountId;
    counterAccountId = from;
    _accountTouched = true;
    notifyListeners();
  }

  void setDate(String value) {
    occurredOn = value;
    notifyListeners();
  }

  void setNotes(String value) => notes = value;
  void setMerchant(String value) => merchant = value;

  void setTags(List<String> ids) {
    tagIds = ids;
    notifyListeners();
  }

  void setRate(String value) {
    rate = value.trim();
    if (rate != _rateSeed) {
      quotedAt = DateTime.now().toUtc().toIso8601String();
      _rateSeed = rate;
    }
    notifyListeners();
  }

  /// Saves through the list model. True when stored or queued offline.
  Future<bool> save() async {
    final from = source;
    if (from == null ||
        amount <= BigInt.zero ||
        (transfer && destination == null)) {
      invalid = true;
      notifyListeners();
      return false;
    }
    saving = true;
    notifyListeners();
    final draft = TransactionDraft(
      type: type,
      occurredOn: occurredOn,
      accountId: from.id,
      counterAccountId: transfer ? counterAccountId : null,
      magnitude: amount,
      clientIds: transfer ? clientIds : [clientIds.first],
      categoryId: transfer ? null : categoryId,
      notes: notes,
      merchant: transfer ? null : merchant,
      tagIds: tagIds,
      rate: cross ? rate : null,
      quotedAt: cross ? quotedAt : null,
    );
    final ok = await model.save(draft, existing: existing);
    saving = false;
    invalid = !ok;
    notifyListeners();
    return ok;
  }

  String? _defaultCategory() {
    if (type != TransactionType.expense) return null;
    return model.preferredCategoryId();
  }

  void _syncDefaults() {
    if (!isNew) return;
    var changed = false;
    if (!_accountTouched) {
      final preferred = model.preferredAccountId();
      if (preferred != null &&
          preferred != accountId &&
          preferred != counterAccountId) {
        accountId = preferred;
        changed = true;
      }
    }
    if (!_categoryTouched &&
        categoryId == null &&
        type == TransactionType.expense) {
      categoryId = model.preferredCategoryId();
      changed = categoryId != null || changed;
    }
    if (changed) {
      _initial = _snapshot();
      notifyListeners();
    }
  }

  String _snapshot() => [
    type,
    amount,
    accountId,
    counterAccountId,
    categoryId,
    occurredOn,
    notes,
    merchant,
    tagIds.join(','),
    rate,
  ].join('|');

  @override
  void dispose() {
    model.removeListener(_syncDefaults);
    super.dispose();
  }
}
