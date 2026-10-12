import '../../sync/domain/sync_item.dart';
import '../domain/transaction.dart';

SyncMutation mutationFromCommand(
  TransactionCommand command, {
  String? serverId,
}) {
  return SyncMutation(
    action: serverId == null ? SyncAction.create : SyncAction.update,
    clientId: command.legs.first.clientId,
    serverId: serverId,
    version: command.version,
    type: command.type,
    occurredOn: command.occurredOn,
    categoryId: command.categoryId,
    notes: command.notes,
    rate: command.rate,
    quotedAt: command.quotedAt,
    legs: [
      for (final leg in command.legs)
        SyncLeg(
          clientId: leg.clientId,
          accountId: leg.accountId,
          currencyCode: leg.currencyCode,
          amountMinor: leg.amountMinor.toString(),
        ),
    ],
  );
}

SyncMutation mutationFromBundle(TransactionBundle bundle, SyncAction action) {
  return SyncMutation(
    action: action,
    clientId: bundle.legs.first.clientId,
    serverId: bundle.id,
    version: bundle.version,
    type: bundle.type,
    occurredOn: bundle.occurredOn,
  );
}
