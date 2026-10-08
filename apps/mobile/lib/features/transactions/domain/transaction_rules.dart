import 'package:dartz/dartz.dart';

import '../../../core/time/calendar_date.dart';
import '../../auth/domain/auth_repository.dart';
import '../../categories/domain/finance_category.dart';
import '../../wallets/domain/wallet.dart';
import 'transaction.dart';
import 'transaction_money.dart';

final RegExp _uuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

String? defaultAccountId({
  required List<Wallet> wallets,
  required List<TxLeg> recentLegs,
}) {
  final active = wallets.where((wallet) => !wallet.archived).toList()
    ..sort((a, b) {
      final order = a.sortOrder.compareTo(b.sortOrder);
      if (order != 0) return order;
      final created = a.createdAt.compareTo(b.createdAt);
      return created != 0 ? created : a.id.compareTo(b.id);
    });
  if (active.isEmpty) return null;
  final ids = active.map((wallet) => wallet.id).toSet();
  for (final leg in recentLegs) {
    if (ids.contains(leg.accountId)) return leg.accountId;
  }
  return active.first.id;
}

String? defaultCategoryId(List<FinanceCategory> recent) =>
    recent.isEmpty ? null : recent.first.id;

Either<AuthFailure, TransactionCommand> prepareTransaction(
  TransactionDraft draft,
  List<Wallet> wallets,
  List<WalletCurrency> currencies,
  List<FinanceCategory> categories, {
  TransactionBundle? existing,
}) {
  if (!isCalendarDate(draft.occurredOn) || draft.magnitude <= BigInt.zero) {
    return left(const AuthFailure(AuthError.invalidInput));
  }
  final notes = draft.notes?.trim();
  final storedNotes = notes == null || notes.isEmpty ? null : notes;
  if (storedNotes != null && storedNotes.length > 2000) {
    return left(const AuthFailure(AuthError.invalidInput));
  }
  if (existing != null) {
    if (existing.deleted || existing.version >= 2147483647) {
      return left(const AuthFailure(AuthError.conflict));
    }
    if (existing.type != draft.type ||
        existing.legs.length != draft.clientIds.length ||
        existing.legs.indexed.any(
          (item) => item.$2.clientId != draft.clientIds[item.$1],
        )) {
      return left(const AuthFailure(AuthError.invalidInput));
    }
  }
  final expected = draft.type == TransactionType.transfer ? 2 : 1;
  if (draft.clientIds.length != expected ||
      draft.clientIds.toSet().length != expected ||
      draft.clientIds.any((id) => !_uuid.hasMatch(id))) {
    return left(const AuthFailure(AuthError.invalidInput));
  }
  final source = _activeWallet(wallets, draft.accountId);
  if (source == null) return left(const AuthFailure(AuthError.invalidInput));
  final sourceCurrency = _currency(currencies, source.draft.currency);
  if (sourceCurrency == null) {
    return left(const AuthFailure(AuthError.invalidInput));
  }
  final categoryIds = categories.map((item) => item.id).toSet();
  if (draft.type == TransactionType.expense &&
      (draft.categoryId == null || !categoryIds.contains(draft.categoryId))) {
    return left(const AuthFailure(AuthError.invalidInput));
  }
  if (draft.type == TransactionType.income &&
      draft.categoryId != null &&
      !categoryIds.contains(draft.categoryId)) {
    return left(const AuthFailure(AuthError.invalidInput));
  }
  final signed = draft.type == TransactionType.income
      ? draft.magnitude
      : -draft.magnitude;
  if (!inInt64(signed)) return left(const AuthFailure(AuthError.invalidInput));
  if (draft.type != TransactionType.transfer) {
    if (draft.rate != null) {
      return left(const AuthFailure(AuthError.invalidInput));
    }
    return right(
      TransactionCommand(
        type: draft.type,
        occurredOn: draft.occurredOn,
        categoryId: draft.categoryId,
        notes: storedNotes,
        version: existing?.version,
        legs: [
          TransactionLegCommand(
            clientId: draft.clientIds.first,
            accountId: source.id,
            currencyCode: source.draft.currency,
            amountMinor: signed,
          ),
        ],
      ),
    );
  }
  final destination = _activeWallet(wallets, draft.counterAccountId);
  if (destination == null || destination.id == source.id) {
    return left(const AuthFailure(AuthError.invalidInput));
  }
  final destinationCurrency = _currency(currencies, destination.draft.currency);
  if (destinationCurrency == null) {
    return left(const AuthFailure(AuthError.invalidInput));
  }
  final BigInt destinationAmount;
  String? rate;
  String? quotedAt;
  if (source.draft.currency == destination.draft.currency) {
    if (draft.rate != null) {
      return left(const AuthFailure(AuthError.invalidInput));
    }
    destinationAmount = draft.magnitude;
  } else {
    final normalized = draft.rate == null ? null : normalizeRate(draft.rate!);
    final converted = normalized == null
        ? null
        : convertedMinor(
            signed,
            normalized,
            sourceCurrency.minorDigits,
            destinationCurrency.minorDigits,
          );
    if (converted == null ||
        draft.quotedAt == null ||
        !_hasZone(draft.quotedAt!)) {
      return left(const AuthFailure(AuthError.invalidInput));
    }
    destinationAmount = converted;
    rate = normalized;
    quotedAt = draft.quotedAt;
  }
  if (!inInt64(destinationAmount)) {
    return left(const AuthFailure(AuthError.invalidInput));
  }
  return right(
    TransactionCommand(
      type: TransactionType.transfer,
      occurredOn: draft.occurredOn,
      categoryId: null,
      notes: storedNotes,
      rate: rate,
      quotedAt: quotedAt,
      version: existing?.version,
      legs: [
        TransactionLegCommand(
          clientId: draft.clientIds[0],
          accountId: source.id,
          currencyCode: source.draft.currency,
          amountMinor: signed,
        ),
        TransactionLegCommand(
          clientId: draft.clientIds[1],
          accountId: destination.id,
          currencyCode: destination.draft.currency,
          amountMinor: destinationAmount,
        ),
      ],
    ),
  );
}

Wallet? _activeWallet(List<Wallet> wallets, String? id) {
  if (id == null) return null;
  for (final wallet in wallets) {
    if (wallet.id == id && !wallet.archived) return wallet;
  }
  return null;
}

WalletCurrency? _currency(List<WalletCurrency> currencies, String code) {
  for (final currency in currencies) {
    if (currency.code == code) return currency;
  }
  return null;
}

bool _hasZone(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return false;
  return value.endsWith('Z') || RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(value);
}
