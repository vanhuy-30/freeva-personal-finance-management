import { Inject, Injectable } from '@nestjs/common';
import { calendarDate, minor, TransactionError } from '../transactions/domain/transaction';
import type { CreateTransactionDto, UpdateTransactionDto } from '../transactions/transaction.dto';
import { TransactionService } from '../transactions/transaction.service';
import { amountsDiffer, selectDuplicates, SyncError, DUPLICATE_WINDOW_MS } from './domain/sync';
import { SYNC_REPOSITORY, type SyncRepository } from './domain/sync.repository';
import type { SyncOperationDto, SyncRequestDto } from './sync.dto';

type PublicLeg = { id: string; clientId: string; accountId: string; amountMinor: string; occurredOn: string; createdAt: string };
type PublicBundle = { legs: PublicLeg[]; fx: { quotedAt: string } | null };
type ItemError = { code: string; message: string; details: [] };
export interface SyncItem {
  opId: string;
  status: 'applied' | 'replayed' | 'conflict' | 'rejected';
  review: boolean;
  transaction: PublicBundle | null;
  error: ItemError | null;
  duplicates: { id: string; clientId: string }[];
}
const item = (opId: string, status: SyncItem['status'], transaction: PublicBundle | null, review: boolean, duplicates: SyncItem['duplicates'], error: ItemError | null): SyncItem =>
  ({ opId, status, review, transaction, error, duplicates });
const failure = (code: string): ItemError => ({
  code, details: [],
  message: code === 'TRANSACTIONS_UNAVAILABLE' ? 'Transactions are temporarily unavailable' : 'Transaction request could not be completed',
});
const requestedAmounts = (op: SyncOperationDto) => {
  const legs = op.action === 'create' || (op.action === 'update' && op.body?.legs) ? op.body?.legs : undefined;
  return legs?.map(leg => ({ clientId: leg.clientId, amountMinor: minor(leg.amountMinor) }));
};
@Injectable()
export class SyncService {
  constructor(
    private readonly transactions: TransactionService,
    @Inject(SYNC_REPOSITORY) private readonly schemas: SyncRepository,
  ) {}
  async apply(userId: string, dto: SyncRequestDto) {
    if (new Set(dto.operations.map(op => op.opId)).size !== dto.operations.length) throw new SyncError('VALIDATION_ERROR');
    const schemaVersion = await this.schemas.schemaVersion();
    if (schemaVersion === null) throw new SyncError('SYNC_UNAVAILABLE');
    if (schemaVersion !== dto.schemaVersion) throw new SyncError('SYNC_SCHEMA_MISMATCH');
    const results: SyncItem[] = [];
    for (const op of dto.operations) {
      let outcome: SyncItem;
      try { outcome = await this.mutate(userId, op); }
      catch (error) {
        const failed = await this.failed(userId, op, error);
        results.push(failed);
        if (!(error instanceof TransactionError) || failed.error?.code === 'TRANSACTIONS_UNAVAILABLE') break;
        continue;
      }
      if (outcome.status === 'applied' && op.action === 'create' && outcome.transaction) {
        try { outcome.duplicates = await this.duplicates(userId, outcome.transaction); }
        catch { results.push(outcome); break; }
      }
      results.push(outcome);
    }
    return { schemaVersion, results };
  }
  private async mutate(userId: string, op: SyncOperationDto): Promise<SyncItem> {
    if (op.action === 'create') {
      const result = await this.transactions.create(userId, op.body as CreateTransactionDto);
      return item(op.opId, result.created ? 'applied' : 'replayed', result.transaction, false, [], null);
    }
    if (op.action === 'update') {
      return item(op.opId, 'applied', await this.transactions.update(userId, op.id!, op.body as UpdateTransactionDto), false, [], null);
    }
    await this.transactions.delete(userId, op.id!, op.version!);
    return item(op.opId, 'applied', null, false, [], null);
  }
  private async failed(userId: string, op: SyncOperationDto, error: unknown): Promise<SyncItem> {
    if (!(error instanceof TransactionError)) return item(op.opId, 'rejected', null, false, [], failure('TRANSACTIONS_UNAVAILABLE'));
    try { return await this.conflict(userId, op, error); }
    catch (loadError) {
      if (loadError instanceof TransactionError) return item(op.opId, 'rejected', null, false, [], failure(loadError.code));
      return item(op.opId, 'rejected', null, false, [], failure('TRANSACTIONS_UNAVAILABLE'));
    }
  }
  private async conflict(userId: string, op: SyncOperationDto, error: TransactionError): Promise<SyncItem> {
    if (error.code !== 'TRANSACTION_CONFLICT') return item(op.opId, 'rejected', null, false, [], failure(error.code));
    let server: PublicBundle | null = null;
    try { server = await this.server(userId, op); }
    catch (loadError) {
      if (!(loadError instanceof TransactionError) || loadError.code !== 'TRANSACTION_NOT_FOUND') throw loadError;
    }
    const review = amountsDiffer(requestedAmounts(op), server ? server.legs.map(leg => ({ clientId: leg.clientId, amountMinor: minor(leg.amountMinor) })) : null);
    return item(op.opId, 'conflict', server, review, [], failure('TRANSACTION_CONFLICT'));
  }
  private async server(userId: string, op: SyncOperationDto): Promise<PublicBundle | null> {
    if (op.action === 'create') {
      for (const leg of op.body?.legs ?? []) {
        const found = await this.transactions.findByClientId(userId, leg.clientId);
        if (found) return found;
      }
      return null;
    }
    return this.transactions.find(userId, op.id!);
  }
  private async duplicates(userId: string, transaction: PublicBundle) {
    const createdAt = new Date(Math.min(...transaction.legs.map(leg => new Date(leg.createdAt).getTime())));
    const occurredOn = calendarDate(transaction.legs[0].occurredOn);
    const legs = transaction.legs.map(leg => ({ accountId: leg.accountId, amountMinor: minor(leg.amountMinor) }));
    const clientIds = transaction.legs.map(leg => leg.clientId);
    const candidates = await this.transactions.recentMatches(userId, {
      occurredOn, createdAfter: new Date(createdAt.getTime() - DUPLICATE_WINDOW_MS), createdBefore: createdAt, excludeClientIds: clientIds, legs,
    });
    return selectDuplicates({ clientIds, legs, occurredOn, createdAt }, candidates);
  }
}
