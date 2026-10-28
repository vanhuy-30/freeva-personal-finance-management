import type { Bill, BillInput, BillPatch, BillQuery } from './bill';

export const BILL_REPOSITORY = Symbol('BILL_REPOSITORY');

export interface BillRepository {
  create(userId: string, input: BillInput): Promise<{ bill: Bill; created: boolean }>;
  find(userId: string, id: string): Promise<Bill>;
  list(userId: string, query: BillQuery): Promise<{ items: Bill[]; total: number; today: string }>;
  update(userId: string, id: string, patch: BillPatch): Promise<Bill>;
  delete(userId: string, id: string, version: number): Promise<void>;
  pay(userId: string, id: string, transactionId: string, version: number): Promise<Bill>;
  unpay(userId: string, id: string, version: number): Promise<Bill>;
  /** Profile timezone calendar day for overdue flags. */
  todayForUser(userId: string, now?: Date): Promise<string>;
}
