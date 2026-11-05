import type { PersonalDebtDirection, PersonalDebtRecord } from './personal-debt';

export const PERSONAL_DEBT_REPOSITORY = Symbol('PERSONAL_DEBT_REPOSITORY');

/** Currency comes from the wallet, so a debt can never disagree with the leg it books. */
export type PersonalDebtCreateInput = {
  clientId: string;
  direction: PersonalDebtDirection;
  counterparty: string;
  amountMinor: bigint;
  accountId: string;
  occurredOn: string;
  dueDate: string | null;
  note: string | null;
};

export type PersonalDebtPatch = {
  version: number;
  counterparty?: string;
  dueDate?: string | null;
  note?: string | null;
};

export type PersonalDebtPaymentInput = {
  clientId: string;
  accountId: string | null;
  amountMinor: bigint;
  paidOn: string;
};

export type PersonalDebtPaymentRecord = {
  id: string;
  clientId: string;
  accountId: string;
  amountMinor: bigint;
  paidOn: string;
  createdAt: Date;
};

export type PersonalDebtContext = { today: string };

export interface PersonalDebtRepository {
  context(userId: string): Promise<PersonalDebtContext>;
  list(userId: string, includeArchived: boolean): Promise<PersonalDebtRecord[]>;
  find(userId: string, id: string): Promise<PersonalDebtRecord>;
  create(userId: string, input: PersonalDebtCreateInput): Promise<{ debt: PersonalDebtRecord; created: boolean }>;
  update(userId: string, id: string, patch: PersonalDebtPatch): Promise<PersonalDebtRecord>;
  archive(userId: string, id: string, version: number): Promise<void>;
  pay(userId: string, id: string, input: PersonalDebtPaymentInput): Promise<{ debt: PersonalDebtRecord; created: boolean }>;
  payments(userId: string, id: string): Promise<PersonalDebtPaymentRecord[]>;
}
