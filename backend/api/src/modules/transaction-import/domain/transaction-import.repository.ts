import type { TransactionInput } from '../../transactions/domain/transaction';
import type { ExistingTransaction, ImportAccount, ImportCategory, RowError } from './transaction-import';

export const TRANSACTION_IMPORT_REPOSITORY = Symbol('TRANSACTION_IMPORT_REPOSITORY');

export interface ImportContext { accounts: ImportAccount[]; categories: ImportCategory[]; existing: ExistingTransaction[] }

export interface ImportBatchRecord {
  id: string;
  clientId: string;
  preset: string;
  rowCount: number;
  createdCount: number;
  duplicateCount: number;
  invalidCount: number;
  /** Imported transactions still active (not deleted since). */
  remainingCount: number;
  undoneAt: Date | null;
  createdAt: Date;
}

export interface CommitRow { rows: number[]; input: TransactionInput }
export type CommitOutcome = { rows: number[]; status: 'created' } | { rows: number[]; status: 'invalid'; error: RowError };

export interface CommitInput {
  clientId: string;
  preset: string;
  rowCount: number;
  /** Rows to write. */
  rows: CommitRow[];
  skippedDuplicates: number;
  plannedInvalid: number;
}

export type UndoSkip = { transactionId: string; reason: 'modified' | 'linked' };

export interface TransactionImportRepository {
  /** Active wallets/categories, plus non-deleted income/expense/transfer legs inside the file's date range. */
  context(userId: string, range: { from: string; to: string } | null): Promise<ImportContext>;
  /** One database transaction; a repeated `clientId` returns the stored batch and `outcomes: null`. */
  commit(userId: string, input: CommitInput): Promise<{ batch: ImportBatchRecord; outcomes: CommitOutcome[] | null; created: boolean }>;
  find(userId: string, id: string): Promise<ImportBatchRecord>;
  /** Soft-deletes every untouched imported transaction; edited or linked ones are reported, never deleted. */
  undo(userId: string, id: string): Promise<{ batch: ImportBatchRecord; undone: number; skipped: UndoSkip[] }>;
}
