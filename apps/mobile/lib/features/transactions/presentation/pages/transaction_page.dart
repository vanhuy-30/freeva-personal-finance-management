import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../sync/presentation/widgets/sync_status_banner.dart';
import '../../domain/transaction_filter.dart';
import '../viewmodels/transaction_view_model.dart';
import '../widgets/transaction_editor.dart';
import '../widgets/transaction_page_actions.dart';
import '../widgets/transaction_filter_bar.dart';
import '../widgets/transaction_filter_sheet.dart';
import '../widgets/transaction_list_body.dart';

/// Giao dịch (C1.1): filter chips, totals for the filter, rows by day.
class TransactionPage extends StatefulWidget {
  const TransactionPage({this.record = false, super.key});

  /// Deep link `/transactions?record=1` opens the editor once ready.
  final bool record;

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  late final TransactionViewModel model = getIt<TransactionViewModel>();
  bool prompted = false;

  @override
  void initState() {
    super.initState();
    model.addListener(_maybeRecord);
    if (!model.composerReady) Future.microtask(model.load);
  }

  void _maybeRecord() {
    if (!widget.record || prompted || !model.composerReady) return;
    if (model.preferredAccountId() == null) return;
    prompted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          builder: (_) => TransactionEditor(model: model),
        ),
      );
    });
  }

  Future<void> _openSheet() async {
    final picked = await showTransactionFilterSheet(context, model);
    if (picked != null) await model.setFilter(picked);
  }

  @override
  void dispose() {
    model.removeListener(_maybeRecord);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) {
      final s = S.of(context);
      final margin = context.screenMargin;
      final filter = model.filter;
      final names = {
        for (final w in model.wallets) w.id: w.draft.name,
        for (final c in model.categories) c.id: c.name,
        for (final t in model.tags) t.id: t.name,
      };
      return Scaffold(
        appBar: FreevaTopBar(
          title: s.transactionTitle,
          kind: FreevaTopBarKind.largeTitle,
          action: TransactionPageActions(
            filtered: filter.narrowed,
            onFilter: _openSheet,
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                margin,
                FreevaSpace.s2,
                0,
                FreevaSpace.s3,
              ),
              child: TransactionFilterBar(
                filter: filter,
                range: rangeFor(
                  filter.period,
                  model.today() ?? '2000-01-01',
                  model.fiscalDay,
                  filter.custom,
                ),
                names: (id) => names[id] ?? '',
                onChanged: model.setFilter,
                onOpenSheet: _openSheet,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: margin),
              child: const SyncStatusBanner(),
            ),
            Expanded(child: TransactionListBody(model: model)),
          ],
        ),
      );
    },
  );
}
