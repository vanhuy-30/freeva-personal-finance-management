import type { Category, CategoryInput, CategoryPatch, CategoryQuery } from './category';
export const CATEGORY_REPOSITORY = Symbol('CATEGORY_REPOSITORY');
export interface CategoryRepository {
  initialize(userId: string): Promise<void>;
  create(userId: string, input: CategoryInput): Promise<{ category: Category; created: boolean }>;
  find(userId: string, id: string): Promise<Category>;
  list(userId: string, query: CategoryQuery): Promise<{ items: Category[]; total: number }>;
  recent(userId: string): Promise<Category[]>;
  update(userId: string, id: string, patch: CategoryPatch): Promise<Category>;
  delete(userId: string, id: string, version: number, replacementCategoryId?: string): Promise<void>;
}
