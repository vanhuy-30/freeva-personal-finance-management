import type { CardInstallmentRecord, CardInstallmentStatus } from './card-installment';

export const CARD_INSTALLMENT_REPOSITORY = Symbol('CARD_INSTALLMENT_REPOSITORY');

export type CardInstallmentCreateInput = {
  clientId: string;
  transactionId: string;
  installmentCount: number;
  /** null = even split rounded up. */
  installmentMinor: bigint | null;
  firstDueOn: string;
};

export type CardInstallmentPreviewInput = Omit<CardInstallmentCreateInput, 'clientId'>;

/** What a plan over the purchase would be, without writing anything. */
export type CardInstallmentPreview = {
  transactionId: string;
  accountId: string;
  currencyCode: string;
  totalMinor: bigint;
  installmentMinor: bigint;
  installmentCount: number;
  firstDueOn: string;
};

export type CardInstallmentFilter = { accountId?: string; status?: CardInstallmentStatus };

export interface CardInstallmentRepository {
  /** Today in the profile timezone. */
  today(userId: string): Promise<string>;
  list(userId: string, filter: CardInstallmentFilter): Promise<CardInstallmentRecord[]>;
  find(userId: string, id: string): Promise<CardInstallmentRecord>;
  create(userId: string, input: CardInstallmentCreateInput): Promise<{ plan: CardInstallmentRecord; created: boolean }>;
  /** Same checks as create (purchase, count, amount, first day) but read-only. */
  preview(userId: string, input: CardInstallmentPreviewInput): Promise<CardInstallmentPreview>;
  /** Prepaid or cancelled: the schedule stops, the purchase expense is untouched. */
  close(userId: string, id: string, version: number): Promise<CardInstallmentRecord>;
}
