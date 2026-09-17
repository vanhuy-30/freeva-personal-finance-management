export const AUDIT_EVENT_REPOSITORY = Symbol('AUDIT_EVENT_REPOSITORY');

export type StaffUserLookupAudit = {
  actorId: string;
  targetId: string | null;
  outcome: 'success' | 'failure';
};

export interface AuditEventRepository {
  recordStaffUserLookup(event: StaffUserLookupAudit): Promise<void>;
}
