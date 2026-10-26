import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../transactions/presentation/viewmodels/transaction_view_model.dart';
import '../../domain/sync_item.dart';

/// One line of the comparison: what each side has and whether they differ.
class CompareField {
  const CompareField(this.label, this.mine, this.saved);

  final String label;
  final String mine;
  final String saved;
  bool get differs => mine != saved;
}

const _none = '—';

/// Fields shown for a conflict. Amount, category and note always; date and
/// store only when they differ. A delete shows "Đã xoá" on this device's side.
List<CompareField> compareFields(
  S s,
  SyncQueueItem item,
  TransactionViewModel tx,
  String locale,
) {
  final server = item.server!;
  int digits(String code) =>
      tx.currencies
          .where((c) => c.code == code)
          .map((c) => c.minorDigits)
          .firstOrNull ??
      0;
  String category(String? id) =>
      tx.categories.where((c) => c.id == id).map((c) => c.name).firstOrNull ??
      _none;
  String text(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? _none : trimmed;
  }

  final savedAmount = signedMoney(
    server.amountMinor,
    digits(server.currencyCode),
    locale,
  );
  if (item.action == SyncAction.delete) {
    return [
      CompareField(s.syncFieldAmount, s.syncCompareDeleted, savedAmount),
      CompareField(
        s.syncFieldCategory,
        s.syncCompareDeleted,
        category(server.categoryId),
      ),
      CompareField(s.syncFieldNotes, s.syncCompareDeleted, text(server.notes)),
    ];
  }
  final leg = item.legs.isEmpty
      ? null
      : item.legs.firstWhere(
          (l) => l.amountMinor.startsWith('-'),
          orElse: () => item.legs.first,
        );
  final mineAmount = leg == null
      ? _none
      : signedMoney(leg.amountMinor, digits(leg.currencyCode), locale);
  final fields = [
    CompareField(s.syncFieldAmount, mineAmount, savedAmount),
    CompareField(
      s.syncFieldCategory,
      category(item.categoryId),
      category(server.categoryId),
    ),
    CompareField(s.syncFieldNotes, text(item.notes), text(server.notes)),
    if ((item.occurredOn ?? server.occurredOn) != server.occurredOn)
      CompareField(
        s.syncFieldDate,
        item.occurredOn ?? _none,
        server.occurredOn,
      ),
    if (text(item.merchant) != text(server.merchant))
      CompareField(
        s.syncFieldMerchant,
        text(item.merchant),
        text(server.merchant),
      ),
  ];
  return fields;
}

/// "−65.000" with its sign, for the compare cards.
String signedMoney(String amountMinor, int digits, String locale) {
  final minor = BigInt.tryParse(amountMinor) ?? BigInt.zero;
  final text = formatMoneyText(minor.abs(), digits, locale);
  return '${minor.isNegative ? '−' : (minor > BigInt.zero ? '+' : '')}$text';
}
