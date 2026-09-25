import type { TransactionBundle, TransactionInput, TransactionLeg, TransactionPatch, TransactionQuery } from './transaction';
export const TRANSACTION_REPOSITORY = Symbol('TRANSACTION_REPOSITORY');
export interface TransactionRepository {
  create(userId: string, input: TransactionInput): Promise<{ transaction: TransactionBundle; created: boolean }>;
  find(userId: string, id: string): Promise<TransactionBundle>;
  list(userId: string, query: TransactionQuery): Promise<{ items: TransactionLeg[]; total: number }>;
  update(userId: string, id: string, patch: TransactionPatch): Promise<TransactionBundle>;
}
