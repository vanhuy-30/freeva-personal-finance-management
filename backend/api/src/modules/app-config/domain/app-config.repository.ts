import type { FlagState } from './app-config';

export const APP_CONFIG_REPOSITORY = Symbol('APP_CONFIG_REPOSITORY');

export type StoredFlag = FlagState & { key: string; version: number; updatedAt: Date; updatedBy: string };
export type StoredValue = { key: string; value: unknown; version: number; updatedAt: Date; updatedBy: string };

export type AppConfigSnapshot = { version: number; flags: StoredFlag[]; values: StoredValue[] };

/**
 * `expectedVersion` is the version the staff member saw: 0 when no row exists yet.
 * Each write is atomic with its change row, its audit event and the global version bump,
 * so nothing is saved unless it is audited. Throws `CONFIG_CONFLICT` on a stale version.
 */
export interface AppConfigRepository {
  snapshot(): Promise<AppConfigSnapshot>;
  saveFlag(input: { key: string; state: FlagState; expectedVersion: number; actorId: string }): Promise<StoredFlag>;
  saveValue(input: { key: string; value: unknown; expectedVersion: number; actorId: string }): Promise<StoredValue>;
  resetValue(input: { key: string; expectedVersion: number; actorId: string }): Promise<void>;
}
