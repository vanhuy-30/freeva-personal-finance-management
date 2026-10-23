import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_retry.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../domain/wallet_totals.dart';
import '../viewmodels/wallet_view_model.dart';
import 'hidden_wallets_link.dart';
import 'wallet_list_row.dart';
import 'wallet_total_header.dart';

/// Body of "Ví của tôi": loading, failed, empty or the list.
class WalletListBody extends StatelessWidget {
  const WalletListBody({
    required this.model,
    required this.hidden,
    required this.onAdd,
    super.key,
  });

  final WalletViewModel model;

  /// "Ẩn số dư" is on.
  final bool hidden;
  final VoidCallback onAdd;

  int _digits(String code) =>
      model.currencies
          .where((c) => c.code == code)
          .map((c) => c.minorDigits)
          .firstOrNull ??
      0;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final margin = context.screenMargin;
    final active = model.active;
    final hiddenCount = model.hidden.length;
    final empty = model.wallets.isEmpty;
    if (empty && model.failure != null && !model.busy) {
      return Center(
        child: ErrorRetry(
          title: s.walletError,
          message: s.homeErrorBody,
          onRetry: model.load,
        ),
      );
    }
    if (empty && (model.busy || model.currencies.isEmpty)) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: margin),
        child: const SkeletonRows(count: 4),
      );
    }
    final link = hiddenCount == 0
        ? null
        : HiddenWalletsLink(
            count: hiddenCount,
            onTap: () => context.push('/wallets/hidden'),
          );
    return RefreshIndicator(
      onRefresh: model.load,
      child: ListView(
        padding: EdgeInsets.fromLTRB(margin, 0, margin, FreevaSpace.s8),
        children: [
          if (active.isEmpty)
            EmptyState(
              title: s.walletEmptyTitle,
              message: s.walletEmptyBody,
              actionLabel: s.walletAdd,
              onAction: onAdd,
            )
          else ...[
            WalletTotalHeader(
              totals: walletTotals(active, model.mainCurrency),
              digitsOf: _digits,
              hidden: hidden,
              onSort: active.length < 2
                  ? null
                  : () => context.push('/wallets/sort'),
            ),
            const SizedBox(height: FreevaSpace.s4),
            FreevaCard(
              list: true,
              padding: const EdgeInsets.symmetric(
                horizontal: FreevaSpace.s4,
                vertical: FreevaSpace.s1,
              ),
              child: Column(
                children: [
                  for (final (i, w) in active.indexed) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: context.colors.listDivider,
                      ),
                    WalletListRow(
                      wallet: w,
                      minorDigits: _digits(w.draft.currency),
                      today: model.today,
                      hidden: hidden,
                      onTap: () => context.push('/wallets/${w.id}'),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (link != null) ...[const SizedBox(height: FreevaSpace.s3), link],
        ],
      ),
    );
  }
}
