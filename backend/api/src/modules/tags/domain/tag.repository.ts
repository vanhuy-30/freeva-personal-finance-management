import type { Tag, TagInput, TagPatch, TagQuery } from './tag';
export const TAG_REPOSITORY = Symbol('TAG_REPOSITORY');
export interface TagRepository {
  create(userId: string, input: TagInput): Promise<{ tag: Tag; created: boolean }>;
  find(userId: string, id: string): Promise<Tag>;
  list(userId: string, query: TagQuery): Promise<{ items: Tag[]; total: number }>;
  update(userId: string, id: string, patch: TagPatch): Promise<Tag>;
  delete(userId: string, id: string, version: number): Promise<void>;
}
