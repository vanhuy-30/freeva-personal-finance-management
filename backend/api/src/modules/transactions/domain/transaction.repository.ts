import type { RefundInput } from './refund';
import type { CsvTransactionRow } from './csv-export';
import type { ReconcileInput, ReconcileResult } from './reconcile';
import type { TransactionBundle, TransactionInput, TransactionLeg, TransactionPatch, TransactionQuery, TransactionSummary } from './transaction';
export const TRANSACTION_REPOSITORY = Symbol('TRANSACTION_REPOSITORY');
export interface RecentMatchQuery {
  occurredOn: Date;
  createdAfter: Date;
  createdBefore: Date;
  excludeClientIds: string[];
  legs: { accountId: string; amountMinor: bigint }[];
}
export interface RecentMatch {
  id: string;
  clientId: string;
  accountId: string;
  amountMinor: bigint;
  occurredOn: Date;
  createdAt: Date;
  deletedAt: Date | null;
}
export interface TransactionRepository {
  create(userId: string, input: TransactionInput): Promise<{ transaction: TransactionBundle; created: boolean }>;
  find(userId: string, id: string): Promise<TransactionBundle>;
  findByClientId(userId: string, clientId: string): Promise<TransactionBundle | null>;
  findRecentMatches(userId: string, query: RecentMatchQuery): Promise<RecentMatch[]>;
  list(userId: string, query: TransactionQuery): Promise<{ items: TransactionLeg[]; total: number; summary: TransactionSummary }>;
  /** BE-P3-010: active legs for the CSV export plus an audit row; throws VALIDATION_ERROR above the row cap. */
  listForCsv(userId: string, query: TransactionQuery, maxRows: number): Promise<CsvTransactionRow[]>;
  update(userId: string, id: string, patch: TransactionPatch): Promise<TransactionBundle>;
  /** BE-P3-008: sum of active refunds per expense id; ids without refunds are absent. */
  refundedTotals(userId: string, expenseIds: string[]): Promise<Map<string, bigint>>;
  refund(userId: string, originalId: string, input: RefundInput): Promise<{ transaction: TransactionBundle; created: boolean }>;
  reconcile(userId: string, accountId: string, input: ReconcileInput): Promise<ReconcileResult>;
}
