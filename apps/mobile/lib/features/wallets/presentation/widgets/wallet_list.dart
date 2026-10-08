import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../viewmodels/wallet_view_model.dart';
import 'wallet_editor.dart';
import 'wallet_money.dart';
import 'wallet_labels.dart';

class WalletList extends StatelessWidget {
  const WalletList({required this.model, required this.archived, super.key});
  final WalletViewModel model;
  final bool archived;
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final items = model.wallets.where((w) => w.archived == archived).toList();
    final enabled = !model.busy && !model.needsReload;
    if (items.isEmpty && !model.busy && model.failure == null) {
      return Center(
        child: Text(archived ? s.walletHiddenEmpty : s.walletEmpty),
      );
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final w = items[index];
        final currency = model.currencies
            .where((c) => c.code == w.draft.currency)
            .firstOrNull;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  w.draft.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(walletTypeLabel(s, w.draft.type)),
                if (currency != null)
                  Text(
                    s.walletBalance(
                      walletMoney(
                        w.balance,
                        currency,
                        Localizations.localeOf(context).toString(),
                      ),
                      currency.code,
                    ),
                  ),
                Wrap(
                  children: [
                    TextButton(
                      onPressed: enabled && currency != null
                          ? () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    WalletEditor(model: model, wallet: w),
                              ),
                            )
                          : null,
                      child: Text(s.walletEdit),
                    ),
                    TextButton(
                      onPressed: enabled
                          ? () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(
                                    w.archived ? s.walletRestore : s.walletHide,
                                  ),
                                  content: Text(s.walletHideExplanation),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: Text(s.profileCancel),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: Text(
                                        w.archived
                                            ? s.walletRestore
                                            : s.walletHide,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true && context.mounted) {
                                await model.archive(w);
                              }
                            }
                          : null,
                      child: Text(w.archived ? s.walletRestore : s.walletHide),
                    ),
                    if (!archived) ...[
                      IconButton(
                        tooltip: s.walletMoveUp,
                        icon: const Icon(Icons.arrow_upward),
                        onPressed: enabled && index > 0
                            ? () => model.move(w, -1)
                            : null,
                      ),
                      IconButton(
                        tooltip: s.walletMoveDown,
                        icon: const Icon(Icons.arrow_downward),
                        onPressed: enabled && index < items.length - 1
                            ? () => model.move(w, 1)
                            : null,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
