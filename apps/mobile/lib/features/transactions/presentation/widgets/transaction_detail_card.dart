import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/tag_chip.dart';
import '../../domain/transaction.dart';
import 'transaction_day_header.dart';
import 'transaction_naming.dart';

/// Category · Wallet (or From / To) · Date · Tags · Note, as label/value rows.
class TransactionDetailCard extends StatelessWidget {
  const TransactionDetailCard({
    required this.bundle,
    required this.label,
    required this.naming,
    required this.today,
    super.key,
  });

  final TransactionBundle bundle;
  final TransactionLabel label;
  final TransactionNaming naming;
  final String? today;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final transfer = bundle.type == TransactionType.transfer;
    final notes = bundle.notes?.trim();
    // Board: rows 14 top/bottom, key 88 wide 14/22 muted, value 15/500
    // right-aligned (notes 400).
    Widget row(String name, Widget value, {bool center = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: center
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              name,
              style: FreevaTypography.bodyM.copyWith(
                height: 22 / 14,
                color: c.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: FreevaSpace.s3),
          Expanded(child: value),
        ],
      ),
    );
    Text value(String text, {bool plain = false}) => Text(
      text,
      textAlign: TextAlign.end,
      style: FreevaTypography.body.copyWith(
        fontWeight: plain ? FontWeight.w400 : FontWeight.w500,
        height: 22 / 15,
        color: c.textPrimary,
      ),
    );
    final rows = <Widget>[
      if (transfer) ...[
        row(s.txDetailFrom, value(naming.wallet(bundle.legs.first.accountId))),
        if (bundle.legs.length == 2)
          row(s.txDetailTo, value(naming.wallet(bundle.legs.last.accountId))),
      ] else ...[
        row(s.txDetailCategory, value(label.category)),
        row(
          s.txDetailWallet,
          value(naming.wallet(bundle.legs.first.accountId)),
        ),
      ],
      row(
        s.txDetailDate,
        value(
          TransactionDayHeader.label(s, bundle.occurredOn, today ?? '', locale),
        ),
      ),
      if (label.tags.isNotEmpty)
        row(
          s.txDetailTags,
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 6,
            runSpacing: 6,
            children: [
              // IntrinsicWidth: the chip's centred Container would
              // otherwise stretch to the row width.
              for (final t in label.tags)
                IntrinsicWidth(child: TagChip(t, size: TagChipSize.detail)),
            ],
          ),
          center: true,
        ),
      if (notes != null && notes.isNotEmpty)
        row(s.txDetailNotes, value(notes, plain: true)),
    ];
    return FreevaCard(
      list: true,
      padding: const EdgeInsets.symmetric(horizontal: FreevaSpace.s4),
      child: Column(
        children: [
          for (final (i, r) in rows.indexed) ...[
            if (i > 0) Divider(height: 1, color: c.listDivider),
            r,
          ],
        ],
      ),
    );
  }
}
