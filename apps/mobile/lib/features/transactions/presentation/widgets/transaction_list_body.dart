import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_retry.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../sync/presentation/widgets/sync_mark_chip.dart';
import '../../domain/transaction.dart';
import '../viewmodels/transaction_view_model.dart';
import 'transaction_day_list.dart';
import 'transaction_detail_sheet.dart';
import 'transaction_labels.dart';
import 'transaction_naming.dart';
import 'transaction_summary_line.dart';

/// Scrolling part of the list: totals line, day groups, paging, and the
/// loading / error / empty / no-result states.
class TransactionListBody extends StatelessWidget {
  const TransactionListBody({required this.model, this.markFor, super.key});

  final TransactionViewModel model;

  /// Queued change per row (chip / clock); none when null.
  final SyncMark? Function(TransactionBundle)? markFor;

  int _digits(String code) =>
      model.currencies
          .where((c) => c.code == code)
          .map((c) => c.minorDigits)
          .firstOrNull ??
      0;

  String? _recentlySaved() {
    final at = model.lastSavedAt;
    if (at == null ||
        DateTime.now().difference(at) > const Duration(seconds: 5)) {
      return null;
    }
    return model.lastSaved?.id;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final margin = context.screenMargin;
    final rows = model.rows;
    final filter = model.filter;
    final firstLoad =
        rows.isEmpty &&
        (model.listLoading || !model.composerReady) &&
        model.failure == null;
    final Widget content;
    if (firstLoad) {
      content = const FreevaCard(list: true, child: SkeletonRows(count: 5));
    } else if (rows.isEmpty && model.failure != null) {
      content = ErrorRetry(
        title: s.txLoadFailed,
        message: transactionError(s, model.failure!),
        onRetry: model.load,
      );
    } else if (rows.isEmpty && (filter.narrowed || filter.type != null)) {
      content = EmptyState(
        title: s.txNoResultTitle,
        message: s.txNoResultBody,
        actionLabel: s.txNoResultClear,
        onAction: () => model.setFilter(filter.cleared(filter.period)),
      );
    } else if (rows.isEmpty) {
      content = EmptyState(
        title: s.txEmptyTitle,
        message: s.txEmptyBody,
        actionLabel: s.txEmptyAction,
        onAction: () => context.push('/record'),
      );
    } else {
      content = TransactionDayList(
        rows: rows,
        naming: TransactionNaming(
          s,
          categories: model.categories,
          wallets: model.wallets,
          tags: model.tags,
        ),
        digitsOf: _digits,
        mainCurrency: model.profileCurrency,
        today: model.today() ?? '',
        onOpen: (row) => openTransactionDetail(context, model, row),
        highlightId: _recentlySaved(),
        markFor: markFor,
      );
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.extentAfter < 400 && model.hasMore) model.loadMore();
        return false;
      },
      child: RefreshIndicator(
        onRefresh: model.load,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            margin,
            0,
            margin,
            FreevaLayout.navReserve,
          ),
          children: [
            if (!firstLoad && rows.isNotEmpty) ...[
              TransactionSummaryLine(
                summary: model.summary,
                mainCurrency: model.profileCurrency,
                digitsOf: _digits,
              ),
              const SizedBox(height: FreevaSpace.s4),
            ],
            if (model.needsReload)
              Padding(
                padding: const EdgeInsets.only(bottom: FreevaSpace.s3),
                child: Text(
                  s.transactionReloadRequired,
                  style: FreevaTypography.bodyS.copyWith(
                    color: context.colors.statusWarning,
                  ),
                ),
              ),
            content,
            if (model.hasMore && rows.isNotEmpty) const SkeletonRows(count: 1),
          ],
        ),
      ),
    );
  }
}
