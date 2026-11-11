import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/currency_catalog.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../domain/import_models.dart';
import '../viewmodels/import_view_model.dart';

/// One line of the preview list (boards O.7 / R.2): title with a status tag,
/// "date · category · wallet", amount. A suggested category that the row
/// still takes is blue with a 12 sparkles glyph. [onTap] opens R.3.
class ImportPreviewRow extends StatelessWidget {
  const ImportPreviewRow({
    required this.row,
    required this.model,
    required this.divider,
    this.onTap,
    super.key,
  });
  final ImportRow row;
  final ImportViewModel model;
  final bool divider;
  final VoidCallback? onTap;

  String? _tag(S s) {
    if (row.status == ImportRowStatus.duplicate) return s.importTagDuplicate;
    if (row.status != ImportRowStatus.invalid) return null;
    final error = row.errors.firstOrNull ?? ImportRowError.other;
    return switch (error) {
      ImportRowError.dateInvalid => s.importTagDate,
      ImportRowError.amountInvalid => s.importTagAmount,
      ImportRowError.typeUnsupported => s.importTagType,
      ImportRowError.walletUnmapped ||
      ImportRowError.walletAmbiguous => s.importTagWallet,
      ImportRowError.categoryUnmapped ||
      ImportRowError.categoryAmbiguous => s.importTagCategory,
      ImportRowError.categoryKindMismatch => s.importTagCategoryKind,
      ImportRowError.currencyMismatch => s.importTagCurrency,
      ImportRowError.transferUnpaired => s.importTagTransfer,
      ImportRowError.transferSameWallet => s.importTagSameWallet,
      ImportRowError.other => s.importTagOther,
    };
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final tag = _tag(s);
    final duplicate = row.status == ImportRowStatus.duplicate;
    final suggested = row.keepsSuggestion;
    final category = suggested
        ? row.suggestion!.categoryName
        : model.categories
              .where((x) => x.id == row.categoryId)
              .firstOrNull
              ?.name;
    final wallet = model.wallets
        .where((w) => w.id == row.accountId)
        .firstOrNull
        ?.draft
        .name;
    final date = row.occurredOn == null
        ? null
        : '${row.occurredOn!.substring(8, 10)}/${row.occurredOn!.substring(5, 7)}';
    final title = row.merchant?.isNotEmpty == true
        ? row.merchant!
        : row.notes?.isNotEmpty == true
        ? row.notes!
        : row.type == 'transfer'
        ? s.transactionTransfer
        : category ?? '';
    String? amount;
    if (row.amountMinor != null) {
      final digits = model.digitsOf(
        row.currencyCode ?? CurrencyCatalog.current.defaultCode,
      );
      final text = formatMoneyText(row.amountMinor!, digits, locale);
      amount = switch (row.type) {
        'expense' => '−$text',
        'income' => '+$text',
        _ => text,
      };
    }
    final muted = duplicate || row.status == ImportRowStatus.invalid;
    final subStyle = FreevaTypography.label.copyWith(color: c.textSecondary);
    final parts = <InlineSpan>[];
    void part(InlineSpan span) {
      if (parts.isNotEmpty) parts.add(const TextSpan(text: ' · '));
      parts.add(span);
    }

    if (date != null) part(TextSpan(text: date));
    if (category != null) {
      part(
        suggested
            ? TextSpan(
                style: TextStyle(
                  color: c.textLink,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 3),
                      child: Icon(
                        LucideIcons.sparkles,
                        size: 12,
                        color: c.textLink,
                      ),
                    ),
                  ),
                  TextSpan(text: category),
                ],
              )
            : TextSpan(text: category),
      );
    }
    if (wallet != null) part(TextSpan(text: wallet));
    Widget content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 58),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: FreevaTypography.body.copyWith(
                            fontWeight: FontWeight.w500,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                      if (tag != null) ...[
                        const SizedBox(width: 6),
                        _Tag(label: tag, danger: !duplicate),
                      ],
                    ],
                  ),
                  if (parts.isNotEmpty)
                    Text.rich(
                      TextSpan(children: parts),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: subStyle,
                    ),
                ],
              ),
            ),
            if (amount != null) ...[
              const SizedBox(width: 12),
              Text(
                amount,
                maxLines: 1,
                style: FreevaTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: muted ? c.textSecondary : c.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ],
        ),
      ),
    );
    if (onTap != null) {
      content = Semantics(
        button: true,
        container: true,
        child: InkWell(onTap: onTap, child: content),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        border: divider
            ? Border(top: BorderSide(color: c.borderDivider))
            : null,
      ),
      child: content,
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.danger});
  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: danger ? c.statusDangerBg : c.statusWarningBg,
        borderRadius: BorderRadius.circular(FreevaRadius.full),
      ),
      child: SizedBox(
        height: 24,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              style: FreevaTypography.label.copyWith(
                fontWeight: FontWeight.w500,
                color: danger ? c.statusDanger : c.statusWarning,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
