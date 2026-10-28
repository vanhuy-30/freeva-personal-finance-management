import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/money_display.dart';
import '../../../../core/widgets/transaction_row.dart';
import '../../../../core/widgets/transaction_row_text.dart';
import '../../../transactions/domain/transaction.dart';
import 'recent_row_data.dart';

/// "Gần đây": up to 3 rows (queued ones first, marked "Chờ đồng bộ") and
/// "Xem giao dịch". Amounts stay visible when balances are hidden.
class RecentTransactions extends StatelessWidget {
  const RecentTransactions({
    required this.rows,
    required this.digitsOf,
    required this.onOpen,
    super.key,
  });

  final List<RecentRowData> rows;
  final int Function(String) digitsOf;
  final ValueChanged<TransactionBundle> onOpen;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  s.homeRecent,
                  style: FreevaTypography.titleL.copyWith(
                    height: 1.2,
                    color: c.textPrimary,
                  ),
                ),
              ),
            ),
            FreevaButton(
              label: s.homeSeeTransactions,
              variant: FreevaButtonVariant.link,
              onPressed: () => context.go('/transactions'),
            ),
          ],
        ),
        // The link keeps a 44 touch row, so the gap under it is small: the
        // list still starts 66 under the block above, as on the board.
        const SizedBox(height: FreevaSpace.s1),
        FreevaCard(
          list: true,
          padding: const EdgeInsets.symmetric(
            horizontal: FreevaSpace.s4,
            vertical: FreevaSpace.s1,
          ),
          child: rows.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: FreevaSpace.s5),
                  child: Text(
                    s.homeRecentEmpty,
                    textAlign: TextAlign.center,
                    style: FreevaTypography.bodyM.copyWith(
                      color: c.textSecondary,
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (final (i, row) in rows.indexed) ...[
                      if (i > 0) Divider(height: 1, color: c.listDivider),
                      TransactionRow(
                        icon: row.icon,
                        title: row.title,
                        subtitle: row.detail,
                        subtitleWidget: row.bundle == null
                            ? TransactionRowNote(
                                icon: LucideIcons.clock,
                                text: row.detail,
                                color: c.statusInfo,
                              )
                            : null,
                        tone: row.tone,
                        semanticsLabel: spoken(
                          s,
                          row,
                          digitsOf(row.currency),
                          locale,
                        ),
                        onTap: row.bundle == null
                            ? null
                            : () => onOpen(row.bundle!),
                        amount: MoneyDisplay(
                          minor: row.minor,
                          currency: row.currency,
                          minorDigits: digitsOf(row.currency),
                          tone: row.tone,
                          style: FreevaTypography.titleM,
                          showCurrency: false,
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

/// First-run "Gần đây": no header or card, a 48 list tile and
/// "Giao dịch sẽ hiện ở đây" centred (ObHome).
class RecentEmptyHint extends StatelessWidget {
  const RecentEmptyHint({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FreevaSpace.s3),
      child: Column(
        children: [
          ExcludeSemantics(
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: c.bgSubtle,
                borderRadius: BorderRadius.circular(FreevaRadius.md),
              ),
              child: Icon(LucideIcons.list, size: 22, color: c.textSecondary),
            ),
          ),
          const SizedBox(height: FreevaSpace.s2),
          Text(
            S.of(context).homeRecentEmpty,
            textAlign: TextAlign.center,
            style: FreevaTypography.bodyM.copyWith(color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}
