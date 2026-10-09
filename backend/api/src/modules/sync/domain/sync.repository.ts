export const SYNC_REPOSITORY = Symbol('SYNC_REPOSITORY');
export interface SyncRepository {
  schemaVersion(): Promise<number | null>;
}
