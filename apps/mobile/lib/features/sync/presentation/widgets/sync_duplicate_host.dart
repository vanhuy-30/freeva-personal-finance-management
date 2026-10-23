import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../../transactions/domain/transaction.dart';
import '../../../transactions/domain/transaction_use_cases.dart';
import '../../../transactions/presentation/viewmodels/transaction_view_model.dart';
import '../../../transactions/presentation/widgets/transaction_naming.dart';
import '../../domain/sync_item.dart';
import '../viewmodels/sync_view_model.dart';
import 'sync_duplicate_sheet.dart';

/// Wraps the tab shell and asks "Có thể bạn đã ghi rồi" once a synced
/// transaction looks like an earlier one. It waits for a tab root: nothing
/// pops up over a form or a detail screen.
class SyncDuplicateHost extends StatefulWidget {
  const SyncDuplicateHost({required this.child, super.key});

  final Widget child;

  @override
  State<SyncDuplicateHost> createState() => _SyncDuplicateHostState();
}

class _SyncDuplicateHostState extends State<SyncDuplicateHost> {
  final SyncViewModel model = getIt<SyncViewModel>();
  GoRouter? _router;
  var _asking = false;

  @override
  void initState() {
    super.initState();
    model.addListener(_check);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.maybeOf(context);
    if (router == _router) return;
    _router?.routerDelegate.removeListener(_routeChanged);
    _router = router?..routerDelegate.addListener(_routeChanged);
  }

  void _routeChanged() => WidgetsBinding.instance.addPostFrameCallback((_) {
    _check();
  });

  @override
  void dispose() {
    model.removeListener(_check);
    _router?.routerDelegate.removeListener(_routeChanged);
    super.dispose();
  }

  Future<void> _check() async {
    final pair = model.duplicate;
    if (_asking || pair == null || !mounted) return;
    if (ModalRoute.of(context)?.isCurrent != true) return;
    _asking = true;
    try {
      await _ask(pair);
    } finally {
      _asking = false;
      model.dismissDuplicate();
    }
  }

  Future<void> _ask(SyncDuplicate pair) async {
    final cases = getIt<TransactionUseCases>();
    final tx = getIt<TransactionViewModel>();
    final recorded = await cases.read(pair.newId);
    final existing = await cases.read(pair.existingId);
    final a = recorded.fold<TransactionBundle?>((_) => null, (v) => v);
    final b = existing.fold<TransactionBundle?>((_) => null, (v) => v);
    // Without both copies there is nothing to compare; the hint is dropped.
    if (a == null || b == null || a.deleted || b.deleted || !mounted) return;
    if (!tx.composerReady) await tx.load();
    if (!mounted) return;
    final s = S.of(context);
    final naming = TransactionNaming(
      s,
      categories: tx.categories,
      wallets: tx.wallets,
      tags: tx.tags,
    );
    int digits(String code) =>
        tx.currencies
            .where((c) => c.code == code)
            .map((c) => c.minorDigits)
            .firstOrNull ??
        0;
    final choice = await showSyncDuplicateSheet(
      context,
      recorded: a,
      existing: b,
      naming: naming,
      digitsOf: digits,
    );
    if (choice != DuplicateChoice.deleteNew) return;
    if (!await tx.remove(a) || !mounted) return;
    showFreevaToast(
      context,
      message: s.txDeletedToast(naming.kind(a.type)),
      icon: LucideIcons.trash2,
      actionLabel: s.commonUndo,
      onAction: () => tx.undoRemove(a),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
