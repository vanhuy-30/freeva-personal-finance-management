import type { TransactionBundle, TransactionInput, TransactionLeg, TransactionPatch, TransactionQuery } from './transaction';
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
  list(userId: string, query: TransactionQuery): Promise<{ items: TransactionLeg[]; total: number }>;
  update(userId: string, id: string, patch: TransactionPatch): Promise<TransactionBundle>;
}
