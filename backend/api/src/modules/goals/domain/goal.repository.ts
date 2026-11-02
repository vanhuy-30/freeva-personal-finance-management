import type { GoalKind, GoalRecord } from './goal';

export const GOAL_REPOSITORY = Symbol('GOAL_REPOSITORY');

export type GoalCreateInput = {
  clientId: string;
  kind: GoalKind;
  name: string;
  targetMinor: bigint;
  currentMinor: bigint;
  targetDate: string | null;
  accountId: string;
  monthlyContributionMinor: bigint | null;
  icon: string;
  colorToken: string | null;
};

export type GoalPatch = {
  version: number;
  kind?: GoalKind;
  name?: string;
  targetMinor?: bigint;
  targetDate?: string | null;
  monthlyContributionMinor?: bigint | null;
  icon?: string;
  colorToken?: string | null;
};

/** `otherAccountId` null = the money is already in the linked wallet, so only the goal ledger moves. */
export type GoalMoveInput = {
  clientId: string;
  amountMinor: bigint;
  otherAccountId: string | null;
  occurredOn: string;
};

export type GoalContext = {
  today: string;
  /** Average monthly income over the last 90 days, per currency. */
  monthlyIncomeMinor: Record<string, bigint>;
};

export interface GoalRepository {
  context(userId: string): Promise<GoalContext>;
  list(userId: string, includeArchived: boolean): Promise<GoalRecord[]>;
  find(userId: string, id: string): Promise<GoalRecord>;
  create(userId: string, input: GoalCreateInput): Promise<{ goal: GoalRecord; created: boolean }>;
  update(userId: string, id: string, patch: GoalPatch): Promise<GoalRecord>;
  archive(userId: string, id: string, version: number): Promise<void>;
  contribute(userId: string, id: string, input: GoalMoveInput): Promise<{ goal: GoalRecord; created: boolean }>;
  withdraw(userId: string, id: string, input: GoalMoveInput): Promise<{ goal: GoalRecord; created: boolean }>;
  adjust(userId: string, id: string, currentMinor: bigint, version: number): Promise<GoalRecord>;
}
