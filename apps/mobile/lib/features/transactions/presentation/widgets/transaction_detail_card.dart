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
    Widget row(String name, Widget value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              name,
              style: FreevaTypography.bodyS.copyWith(color: c.textSecondary),
            ),
          ),
          Expanded(child: value),
        ],
      ),
    );
    Text value(String text) =>
        Text(text, style: FreevaTypography.body.copyWith(color: c.textPrimary));
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
            runSpacing: 4,
            children: [for (final t in label.tags) TagChip(t)],
          ),
        ),
      if (notes != null && notes.isNotEmpty) row(s.txDetailNotes, value(notes)),
    ];
    return FreevaCard(
      list: true,
      padding: const EdgeInsets.symmetric(
        horizontal: FreevaSpace.s4,
        vertical: 4,
      ),
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
