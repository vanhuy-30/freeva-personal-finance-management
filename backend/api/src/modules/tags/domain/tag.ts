export class TagError extends Error {
  constructor(readonly code: 'VALIDATION_ERROR' | 'TAG_NOT_FOUND' | 'TAG_CONFLICT') { super(code); }
}
export interface TagInput {
  clientId: string;
  name: string;
}
export interface Tag extends TagInput {
  id: string;
  version: number;
  createdAt: Date;
  updatedAt: Date;
  /** Not-deleted transactions carrying the tag; only on list rows. */
  transactionCount?: number;
}
export interface TagPatch {
  version: number;
  name?: string;
}
export interface TagQuery {
  page: number;
  pageSize: number;
}
export function assertTagVersion(actual: number, expected: number) {
  if (actual !== expected || actual >= 2147483647) throw new TagError('TAG_CONFLICT');
}
