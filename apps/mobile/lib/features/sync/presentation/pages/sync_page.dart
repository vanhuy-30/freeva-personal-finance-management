import 'package:flutter/material.dart';

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
import '../../../transactions/presentation/viewmodels/transaction_view_model.dart';
import '../../domain/sync_item.dart';
import '../viewmodels/sync_view_model.dart';
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
      SyncItemView view(SyncQueueItem i) => syncItemView(s, i, transactions);
      Widget group(String title, List<Widget> rows) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              FreevaSpace.s1,
              FreevaSpace.s5,
              FreevaSpace.s1,
              FreevaSpace.s2,
            ),
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: FreevaTypography.overline.copyWith(
                  color: c.textSecondary,
                ),
              ),
            ),
          ),
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
            SyncStatusCard(model: model, now: now),
            if (model.duplicateHint) ...[
              const SizedBox(height: FreevaSpace.s3),
              Text(
                s.syncDuplicateNote,
                style: FreevaTypography.bodyS.copyWith(color: c.textSecondary),
              ),
            ],
            if (holding && model.items.isNotEmpty)
              group(s.syncSectionHolding(model.items.length), [
                for (final item in model.items)
                  SyncItemRow(
                    item: item,
                    view: view(item),
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
                      onRetry: syncCanRetry(item)
                          ? () => model.retry(item.opId)
                          : null,
                      onDiscard: () => _discard(item, view(item)),
                    ),
                ]),
              if (waiting.isNotEmpty)
                group(s.syncSectionWaiting(waiting.length), [
                  for (final item in waiting)
                    SyncItemRow(
                      item: item,
                      view: view(item),
                      detail: syncClock(item.createdAt, locale),
                      compactAction: true,
                      onDiscard: () => _discard(item, view(item)),
                    ),
                ]),
            ],
            const SizedBox(height: FreevaSpace.s6),
            Text(
              s.syncFooter,
              textAlign: TextAlign.center,
              style: FreevaTypography.bodyS.copyWith(color: c.textSecondary),
            ),
          ],
        ),
      );
    },
  );
}
