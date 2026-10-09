export const DUPLICATE_WINDOW_MS = 10 * 60 * 1000;
export const DUPLICATE_LIMIT = 5;
export class SyncError extends Error {
  constructor(readonly code: 'VALIDATION_ERROR' | 'SYNC_SCHEMA_MISMATCH' | 'SYNC_UNAVAILABLE') { super(code); }
}
export interface DuplicateCandidate {
  id: string;
  clientId: string;
  accountId: string;
  amountMinor: bigint;
  occurredOn: Date;
  createdAt: Date;
  deletedAt: Date | null;
}
export interface CreatedTransaction {
  clientIds: string[];
  legs: { accountId: string; amountMinor: bigint }[];
  occurredOn: Date;
  createdAt: Date;
}
export function selectDuplicates(created: CreatedTransaction, candidates: DuplicateCandidate[]) {
  const own = new Set(created.clientIds);
  const start = created.createdAt.getTime() - DUPLICATE_WINDOW_MS;
  const end = created.createdAt.getTime();
  const seen = new Set<string>();
  const matches = candidates.filter(candidate => {
    if (candidate.deletedAt || own.has(candidate.clientId)) return false;
    if (candidate.occurredOn.getTime() !== created.occurredOn.getTime()) return false;
    const at = candidate.createdAt.getTime();
    if (at < start || at > end) return false;
    if (!created.legs.some(leg => leg.accountId === candidate.accountId && leg.amountMinor === candidate.amountMinor)) return false;
    if (seen.has(candidate.id)) return false;
    seen.add(candidate.id);
    return true;
  });
  matches.sort((left, right) => left.createdAt.getTime() - right.createdAt.getTime() || left.id.localeCompare(right.id));
  return matches.slice(0, DUPLICATE_LIMIT).map(({ id, clientId }) => ({ id, clientId }));
}
export function amountsDiffer(
  requested: { clientId: string; amountMinor: bigint }[] | undefined,
  server: { clientId: string; amountMinor: bigint }[] | null,
): boolean {
  if (!requested?.length || !server) return false;
  const current = new Map(server.map(leg => [leg.clientId, leg.amountMinor]));
  return requested.some(leg => {
    const stored = current.get(leg.clientId);
    return stored !== undefined && stored !== leg.amountMinor;
  });
}
