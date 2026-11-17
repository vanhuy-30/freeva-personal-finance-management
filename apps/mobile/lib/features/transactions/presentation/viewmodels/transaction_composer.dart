import 'package:flutter/foundation.dart';

import '../../../categories/domain/finance_category.dart';
import '../../../wallets/domain/wallet.dart';
import '../../domain/transaction.dart';
import '../../domain/transaction_money.dart';
import '../../domain/transaction_rules.dart';
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
    // A copy is a new transaction today (C1.5) with the current clock.
    occurredOn = (copy ? null : from?.occurredOn) ?? model.today() ?? '';
    occurredTime = copy || from == null ? model.nowTime() : from.occurredTime;
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
  String? occurredTime;
  late String notes;
  late String merchant;
  late List<String> tagIds;
  late String rate;
  String? quotedAt;
  late List<String> clientIds;
  bool saving = false;
  bool invalid = false;

  /// What blocked the last save before it reached the server; null once the
  /// user changes anything (MOB-P6-001).
  ComposerMissing? missing;
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

  /// Three quick chips: the chosen category, recent fitting ones, then the
  /// first top-level categories of this type, so income (no history yet)
  /// still shows what it can be filed under (MOB-P6-001).
  List<FinanceCategory> get quick {
    final ids = fitting.map((c) => c.id).toSet();
    final picks = [
      if (category != null) category!,
      for (final c in model.recentCategories)
        if (ids.contains(c.id) && c.id != categoryId) c,
    ];
    for (final c in fitting) {
      if (picks.length >= 3) break;
      if (c.parentId == null && !picks.any((p) => p.id == c.id)) picks.add(c);
    }
    return picks.take(3).toList();
  }

  /// Whether "Cửa hàng" belongs on this form: spending only. Income has no
  /// store; one already stored on an income being edited stays visible.
  bool get hasMerchant =>
      type == TransactionType.expense || (!isNew && merchant.isNotEmpty);

  // Keypad -----------------------------------------------------------------

  void typeKeys(String keys) {
    final next = amount.toString() == '0'
        ? keys.replaceFirst(RegExp(r'^0+'), '')
        : '$amount$keys';
    if (next.isEmpty || next.length > maxDigits) return;
    amount = BigInt.parse(next);
    _changed();
  }

  void backspace() {
    amount = amount ~/ BigInt.from(10);
    _changed();
  }

  /// Any edit clears the last save error: it may no longer apply.
  void _changed() {
    invalid = false;
    missing = null;
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
    _changed();
  }

  void pickCategory(String id) {
    categoryId = id;
    _categoryTouched = true;
    _changed();
  }

  void pickAccount(String id) {
    accountId = id;
    _accountTouched = true;
    if (counterAccountId == id) counterAccountId = null;
    _changed();
  }

  void pickCounter(String id) {
    counterAccountId = id;
    _changed();
  }

  void swap() {
    final from = accountId;
    accountId = counterAccountId;
    counterAccountId = from;
    _accountTouched = true;
    _changed();
  }

  void setDate(String value) {
    occurredOn = value;
    _changed();
  }

  void setWhen({required String date, String? time}) {
    occurredOn = date;
    occurredTime = time;
    _changed();
  }

  void setNotes(String value) => notes = value;
  void setMerchant(String value) => merchant = value;

  void setTags(List<String> ids) {
    tagIds = ids;
    _changed();
  }

  void setRate(String value) {
    rate = value.trim();
    if (rate != _rateSeed) {
      quotedAt = DateTime.now().toUtc().toIso8601String();
      _rateSeed = rate;
    }
    _changed();
  }

  /// Saves through the list model. True when stored or queued offline.
  Future<bool> save() async {
    final from = source;
    missing = from == null
        ? ComposerMissing.wallet
        : amount <= BigInt.zero
        ? ComposerMissing.amount
        : transfer && destination == null
        ? ComposerMissing.destination
        // The API refuses an expense without a category.
        : type == TransactionType.expense && categoryId == null
        ? ComposerMissing.category
        : null;
    if (from == null || missing != null) {
      invalid = true;
      notifyListeners();
      return false;
    }
    saving = true;
    notifyListeners();
    final draft = TransactionDraft(
      type: type,
      occurredOn: occurredOn,
      occurredTime: occurredTime,
      accountId: from.id,
      counterAccountId: transfer ? counterAccountId : null,
      magnitude: amount,
      clientIds: transfer ? clientIds : [clientIds.first],
      categoryId: transfer ? null : categoryId,
      notes: notes,
      merchant: hasMerchant ? merchant : null,
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
    // Recent categories mix both types: an income one ("Lương") must not
    // become the default of an expense.
    final fits = model.recentCategories
        .where((c) => !c.archived && c.kind.fits(false))
        .toList();
    return defaultCategoryId(fits);
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
      categoryId = _defaultCategory();
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
    occurredTime,
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

/// The field a save stopped on, so the screen can open it.
enum ComposerMissing { wallet, amount, destination, category }
