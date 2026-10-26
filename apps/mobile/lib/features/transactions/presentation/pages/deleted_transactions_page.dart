import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../domain/transaction.dart';
import '../viewmodels/transaction_results_view_model.dart';
import '../viewmodels/transaction_view_model.dart';
import '../widgets/transaction_day_list.dart';
import '../widgets/transaction_naming.dart';
import '../widgets/restore_button.dart';

/// Đã xoá (C1.7): soft-deleted transactions by day, muted amounts, a round
/// restore button per row. No permanent delete in Phase 1.
class DeletedTransactionsPage extends StatefulWidget {
  const DeletedTransactionsPage({super.key});

  @override
  State<DeletedTransactionsPage> createState() =>
      _DeletedTransactionsPageState();
}

class _DeletedTransactionsPageState extends State<DeletedTransactionsPage> {
  final main = getIt<TransactionViewModel>();
  late final TransactionResultsViewModel results =
      getIt<TransactionResultsViewModel>(param1: true);

  @override
  void initState() {
    super.initState();
    Future.microtask(results.reload);
  }

  @override
  void dispose() {
    results.dispose();
    super.dispose();
  }

  int _digits(String code) =>
      main.currencies
          .where((c) => c.code == code)
          .map((c) => c.minorDigits)
          .firstOrNull ??
      0;

  Future<void> _restore(TransactionBundle row) async {
    final s = S.of(context);
    if (!await main.restore(row) || !mounted) return;
    showFreevaToast(
      context,
      message: s.txRestoredToast,
      icon: LucideIcons.rotateCcw,
      aboveNav: false,
    );
    await results.reload();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: results,
    builder: (context, _) {
      final s = S.of(context);
      final c = context.colors;
      final margin = context.screenMargin;
      return Scaffold(
        appBar: FreevaTopBar(title: s.txTrashTitle),
        body: ListView(
          padding: EdgeInsets.fromLTRB(
            margin,
            FreevaSpace.s2,
            margin,
            FreevaSpace.s8,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: FreevaSpace.s1),
              child: Text(
                s.txTrashBody,
                style: FreevaTypography.bodyM.copyWith(color: c.textSecondary),
              ),
            ),
            const SizedBox(height: FreevaSpace.s4),
            if (results.loading && results.rows.isEmpty)
              const FreevaCard(list: true, child: SkeletonRows())
            else if (results.rows.isEmpty)
              EmptyState(title: s.txTrashEmpty)
            else
              TransactionDayList(
                rows: results.rows,
                naming: TransactionNaming(
                  s,
                  categories: main.categories,
                  wallets: main.wallets,
                  tags: main.tags,
                ),
                digitsOf: _digits,
                mainCurrency: main.profileCurrency,
                today: main.today() ?? '',
                muted: true,
                showNet: false,
                onOpen: (_) {},
                trailingFor: (row) => RestoreButton(
                  label: s.txTrashRestore,
                  onPressed: () => _restore(row),
                ),
              ),
            if (results.hasMore)
              TextButton(
                onPressed: results.loadMore,
                child: Text(s.transactionLoadMore),
              ),
          ],
        ),
      );
    },
  );
}
