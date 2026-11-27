import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_retry.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../transactions/presentation/viewmodels/transaction_view_model.dart';
import '../../../transactions/presentation/widgets/transaction_editor.dart';
import '../../domain/queued_transaction.dart';
import '../../domain/sync_item.dart';
import '../viewmodels/sync_view_model.dart';

/// Đồng bộ → "Sửa": the transaction form filled with a failed queued change.
/// Saving puts the change back in line (and sends it); closing leaves it as
/// it was.
class SyncEditPage extends StatefulWidget {
  const SyncEditPage({required this.opId, super.key});

  final String opId;

  @override
  State<SyncEditPage> createState() => _SyncEditPageState();
}

class _SyncEditPageState extends State<SyncEditPage> {
  final SyncViewModel sync = getIt<SyncViewModel>();
  final TransactionViewModel model = getIt<TransactionViewModel>();

  /// The item as it was when the form opened. Saving sends it and the queue
  /// may drop it right after, so the form must not follow the live list.
  SyncQueueItem? _item;
  bool _left = false;

  @override
  void initState() {
    super.initState();
    if (!model.composerReady) Future.microtask(model.load);
  }

  SyncQueueItem? get _current => [
    for (final i in sync.items)
      if (i.opId == widget.opId && syncItemEditable(i)) i,
  ].firstOrNull;

  /// The change is gone or no longer fixable by editing (a stale link, or it
  /// was sent in the meantime): back to the list instead of an empty form.
  void _leave() {
    if (_left) return;
    _left = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.popOrGo('/sync');
    });
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([model, sync]),
    builder: (context, _) {
      final s = S.of(context);
      final item = _item ?? _current;
      if (item == null) {
        _leave();
        return const Scaffold(body: SizedBox.shrink());
      }
      if (!model.composerReady) {
        return Scaffold(
          appBar: FreevaTopBar(
            title: s.transactionEdit,
            kind: FreevaTopBarKind.modal,
          ),
          body: Center(
            child: model.failure == null
                ? const CircularProgressIndicator()
                : ErrorRetry(
                    title: s.transactionError,
                    message: s.homeErrorBody,
                    onRetry: model.load,
                  ),
          ),
        );
      }
      final bundle = bundleFromQueueItem(item);
      if (bundle == null) {
        _leave();
        return Scaffold(
          appBar: FreevaTopBar(
            title: s.transactionEdit,
            kind: FreevaTopBarKind.modal,
          ),
          body: EmptyState(title: s.transactionError),
        );
      }
      _item = item;
      return TransactionEditor(model: model, initial: bundle, queued: item);
    },
  );
}
