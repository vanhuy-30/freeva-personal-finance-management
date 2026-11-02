import type { LoanFrequency, LoanKind, LoanRecord } from './loan';

export const LOAN_REPOSITORY = Symbol('LOAN_REPOSITORY');

export type LoanCreateInput = {
  clientId: string;
  kind: LoanKind;
  name: string;
  currencyCode: string;
  principalMinor: bigint;
  outstandingMinor: bigint;
  interestRateBps: number;
  installmentMinor: bigint | null;
  frequency: LoanFrequency;
  startDate: string;
  endDate: string | null;
  nextDueDate: string | null;
  accountId: string | null;
};

export type LoanPatch = {
  version: number;
  kind?: LoanKind;
  name?: string;
  interestRateBps?: number;
  installmentMinor?: bigint | null;
  frequency?: LoanFrequency;
  endDate?: string | null;
  nextDueDate?: string | null;
  accountId?: string | null;
};

/** `principalMinor` / `interestMinor` null = split automatically (interest of the period first). */
export type LoanPaymentInput = {
  clientId: string;
  accountId: string | null;
  amountMinor: bigint;
  principalMinor: bigint | null;
  interestMinor: bigint | null;
  principalCategoryId: string | null;
  interestCategoryId: string | null;
  paidOn: string;
};

export type LoanPaymentRecord = {
  id: string;
  clientId: string;
  principalMinor: bigint;
  interestMinor: bigint;
  paidOn: string;
  createdAt: Date;
};

export type LoanContext = { today: string };

export interface LoanRepository {
  context(userId: string): Promise<LoanContext>;
  list(userId: string, includeArchived: boolean): Promise<LoanRecord[]>;
  find(userId: string, id: string): Promise<LoanRecord>;
  create(userId: string, input: LoanCreateInput): Promise<{ loan: LoanRecord; created: boolean }>;
  update(userId: string, id: string, patch: LoanPatch): Promise<LoanRecord>;
  archive(userId: string, id: string, version: number): Promise<void>;
  pay(userId: string, id: string, input: LoanPaymentInput): Promise<{ loan: LoanRecord; created: boolean }>;
  payments(userId: string, id: string): Promise<LoanPaymentRecord[]>;
  adjust(userId: string, id: string, outstandingMinor: bigint, version: number): Promise<LoanRecord>;
}
