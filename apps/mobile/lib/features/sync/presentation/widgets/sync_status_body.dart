import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../domain/sync_item.dart';
import '../viewmodels/sync_view_model.dart';
import 'sync_labels.dart';

class SyncStatusBody extends StatelessWidget {
  const SyncStatusBody({required this.model, super.key});

  final SyncViewModel model;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final pending = model.items
        .where((item) => item.status == SyncItemStatus.pending)
        .toList();
    final attention = model.items.where(
      (item) => item.status != SyncItemStatus.pending,
    );
    final error = Theme.of(context).colorScheme.error;
    return Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pending.isNotEmpty) Text(s.syncPending(pending.length)),
          for (final item in pending.take(3)) Text(syncItemLabel(s, item)),
          if (model.syncing) Text(s.syncing),
          if (model.schemaMismatch)
            Text(s.syncSchema, style: TextStyle(color: error)),
          if (model.duplicateHint) Text(s.syncDuplicate),
          for (final item in attention) ...[
            Text(syncItemLabel(s, item)),
            Text(
              item.review
                  ? s.syncReview
                  : item.status == SyncItemStatus.conflict
                  ? s.syncConflict
                  : s.syncFailedItem,
              style: TextStyle(color: error),
            ),
            TextButton(
              onPressed: model.syncing ? null : () => model.discard(item.opId),
              child: Text(s.syncDiscard),
            ),
          ],
          if (pending.isNotEmpty)
            OutlinedButton(
              onPressed: model.syncing ? null : model.flush,
              child: Text(s.syncNow),
            ),
        ],
      ),
    );
  }
}
