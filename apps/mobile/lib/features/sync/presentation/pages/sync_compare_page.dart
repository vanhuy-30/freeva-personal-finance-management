import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../transactions/presentation/viewmodels/transaction_view_model.dart';
import '../../domain/sync_item.dart';
import '../viewmodels/sync_view_model.dart';
import '../widgets/sync_compare_card.dart';
import '../widgets/sync_compare_fields.dart';
import '../widgets/sync_item_view.dart';
import '../widgets/sync_labels.dart';

/// Chọn bản giữ lại: this device's change next to the server's copy, the
/// saved one pre-selected because keeping it loses nothing.
class SyncComparePage extends StatefulWidget {
  const SyncComparePage({required this.opId, super.key});

  final String opId;

  @override
  State<SyncComparePage> createState() => _SyncComparePageState();
}

class _SyncComparePageState extends State<SyncComparePage> {
  final SyncViewModel model = getIt<SyncViewModel>();
  final TransactionViewModel transactions = getIt<TransactionViewModel>();
  var _keepMine = false;

  @override
  void initState() {
    super.initState();
    if (!transactions.composerReady) Future.microtask(transactions.load);
  }

  SyncQueueItem? get _item => [
    for (final i in model.items)
      if (i.opId == widget.opId && i.server != null) i,
  ].firstOrNull;

  Future<void> _confirm(SyncQueueItem item) async {
    final navigator = context;
    if (_keepMine) {
      await model.keepLocal(item.opId);
    } else {
      await model.discard(item.opId);
    }
    if (navigator.mounted) navigator.popOrGo('/sync');
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([model, transactions]),
    builder: (context, _) {
      final s = S.of(context);
      final c = context.colors;
      final margin = context.screenMargin;
      final locale = Localizations.localeOf(context).toString();
      final item = _item;
      if (item == null) {
        // Resolved elsewhere (or never comparable): back to the list.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && ModalRoute.of(context)?.isCurrent == true) {
            context.popOrGo('/sync');
          }
        });
        return const Scaffold();
      }
      final fields = compareFields(s, item, transactions, locale);
      final name = syncItemView(s, item, transactions).title;
      final now = DateTime.now();
      final saved = item.server!;
      final base = FreevaTypography.body.copyWith(color: c.textOnWash);
      return Scaffold(
        appBar: FreevaTopBar(
          title: s.syncCompareTitle,
          onLeading: () => context.popOrGo('/sync'),
        ),
        body: ListView(
          padding: EdgeInsets.fromLTRB(
            margin,
            // 14 under the header row, like the board.
            FreevaSpace.s2 - 2,
            margin,
            FreevaSpace.s6,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
              child: Text.rich(
                TextSpan(
                  style: base,
                  children: [
                    TextSpan(text: s.syncCompareIntroA(name)),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: SyncDiffMark(
                        text: s.syncCompareIntroB,
                        style: base,
                      ),
                    ),
                    TextSpan(text: s.syncCompareIntroC),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            SyncCompareCard(
              title: s.syncCompareMine,
              subtitle: s.syncCompareMineWhen(
                syncAt(s, item.createdAt, now, locale),
              ),
              selected: _keepMine,
              onTap: () => setState(() => _keepMine = true),
              rows: [for (final f in fields) (f.label, f.mine, f.differs)],
            ),
            const SizedBox(height: 10),
            SyncCompareCard(
              title: s.syncCompareSaved,
              subtitle: saved.updatedAt == null
                  ? s.syncCompareSavedNoTime
                  : s.syncCompareSavedWhen(
                      syncAt(s, saved.updatedAt!, now, locale),
                    ),
              selected: !_keepMine,
              onTap: () => setState(() => _keepMine = false),
              rows: [for (final f in fields) (f.label, f.saved, f.differs)],
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.only(bottom: 28),
          child: Padding(
            padding: EdgeInsets.fromLTRB(margin, FreevaSpace.s2, margin, 0),
            child: FreevaButton(
              label: _keepMine ? s.syncKeepMine : s.syncKeepSaved,
              size: FreevaButtonSize.l,
              expand: true,
              loading: model.syncing,
              onPressed: () => _confirm(item),
            ),
          ),
        ),
      );
    },
  );
}
