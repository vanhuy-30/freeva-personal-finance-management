import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/freeva_dialog.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../../core/widgets/money_display.dart';
import '../../../../core/widgets/settings_group.dart';
import '../../../transactions/presentation/viewmodels/transaction_view_model.dart';
import '../../domain/sync_item.dart';
import '../viewmodels/sync_view_model.dart';
import '../widgets/sync_done_view.dart';
import '../widgets/sync_item_row.dart';
import '../widgets/sync_item_view.dart';
import '../widgets/sync_labels.dart';
import '../widgets/sync_status_card.dart';

/// Đồng bộ: where things stand, what needs the person, what only waits.
/// Reached from the banner on Giao dịch; no bottom bar.
class SyncPage extends StatefulWidget {
  const SyncPage({super.key});

  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  final SyncViewModel model = getIt<SyncViewModel>();
  final TransactionViewModel transactions = getIt<TransactionViewModel>();

  @override
  void initState() {
    super.initState();
    // Names and amounts come from the loaded categories, wallets and rows.
    if (!transactions.composerReady) Future.microtask(transactions.load);
  }

  Future<void> _discard(SyncQueueItem item, SyncItemView view) async {
    final s = S.of(context);
    final locale = Localizations.localeOf(context).toString();
    final minor = view.minor;
    final message = minor == null
        ? s.syncDiscardMessageShort(view.title)
        : s.syncDiscardMessage(
            view.title,
            '${view.tone == MoneyTone.income ? '+' : '−'}'
            '${formatMoneyText(minor, view.minorDigits, locale)}',
          );
    final confirmed = await showFreevaConfirm(
      context: context,
      title: s.syncDiscardTitle,
      message: message,
      cancelLabel: s.syncDiscardKeep,
      confirmLabel: s.syncDiscardConfirm,
      destructive: true,
      icon: LucideIcons.rotateCcw,
    );
    if (confirmed) await model.discard(item.opId);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([model, transactions]),
    builder: (context, _) {
      final s = S.of(context);
      final c = context.colors;
      final margin = context.screenMargin;
      final locale = Localizations.localeOf(context).toString();
      final now = DateTime.now();
      final holding = model.schemaMismatch;
      final sending = model.syncing && !holding;
      final done =
          model.items.isEmpty &&
          !model.syncing &&
          !holding &&
          model.link == SyncLink.ok;
      SyncItemView view(SyncQueueItem i) => syncItemView(s, i, transactions);
      Widget group(String title, List<Widget> rows) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title),
          FreevaCard(
            list: true,
            padding: const EdgeInsets.symmetric(horizontal: FreevaSpace.s4),
            child: Column(
              children: [
                for (final (i, row) in rows.indexed) ...[
                  if (i > 0) Divider(height: 1, color: c.listDivider),
                  row,
                ],
              ],
            ),
          ),
        ],
      );
      final attention = model.attention;
      final waiting = model.waiting;
      final stamp = model.lastSyncedAt;
      return Scaffold(
        appBar: FreevaTopBar(
          title: s.syncTitle,
          onLeading: () => context.popOrGo('/transactions'),
        ),
        body: ListView(
          padding: EdgeInsets.fromLTRB(
            margin,
            FreevaSpace.s2,
            margin,
            FreevaSpace.s8,
          ),
          children: [
            if (done)
              SyncDoneView(
                title: s.syncAllDone,
                subtitle: stamp == null
                    ? s.syncLastNever
                    : syncLast(s, stamp, now, locale),
              )
            else
              SyncStatusCard(model: model, now: now),
            if (holding && model.items.isNotEmpty)
              group(s.syncSectionHolding(model.items.length), [
                for (final item in model.items)
                  SyncItemRow(
                    item: item,
                    view: view(item),
                    style: SyncRowStyle.holding,
                    detail: syncClock(item.createdAt, locale),
                  ),
              ])
            else ...[
              if (attention.isNotEmpty)
                group(s.syncSectionAttention(attention.length), [
                  for (final item in attention)
                    SyncItemRow(
                      item: item,
                      view: view(item),
                      detail: syncReasonLabel(s, item.reason),
                      onView:
                          item.status == SyncItemStatus.conflict &&
                              item.server != null
                          ? () => context.push('/sync/compare/${item.opId}')
                          : null,
                      onRetry: syncCanRetry(item) && !sending
                          ? () => model.retry(item.opId)
                          : null,
                      onDiscard: sending
                          ? null
                          : () => _discard(item, view(item)),
                    ),
                ]),
              if (waiting.isNotEmpty)
                group(
                  sending
                      ? s.syncSectionSending
                      : s.syncSectionWaiting(waiting.length),
                  [
                    for (final item in waiting)
                      SyncItemRow(
                        item: item,
                        view: view(item),
                        style: sending
                            ? SyncRowStyle.sending
                            : SyncRowStyle.waiting,
                        detail: syncClock(item.createdAt, locale),
                        onDiscard: () => _discard(item, view(item)),
                      ),
                  ],
                ),
            ],
            if (!done && !sending && !holding) ...[
              const SizedBox(height: FreevaSpace.s4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: FreevaSpace.s1),
                child: Text(
                  s.syncFooter,
                  style: FreevaTypography.bodyS.copyWith(
                    color: c.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
}
