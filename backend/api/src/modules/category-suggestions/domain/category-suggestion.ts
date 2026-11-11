/** One merchant → category pair the user accepted (PRD-P5-E01; written by BE-P5-E03). */
export interface SuggestionMapping {
  id: string;
  merchant: string;
  category: { id: string; name: string; iconToken: string | null; colorToken: string | null };
  updatedAt: Date;
}

export class CategorySuggestionError extends Error {
  constructor(readonly code: 'MAPPING_NOT_FOUND') { super(code); }
}

/** Key that makes "Highlands  Coffee" and "highlands coffee" one merchant. */
export function merchantKey(merchant: string): string {
  return merchant.trim().replace(/\s+/g, ' ').toLocaleLowerCase('vi');
}

export const CATEGORY_SUGGESTION_REPOSITORY = Symbol('CATEGORY_SUGGESTION_REPOSITORY');
export interface CategorySuggestionRepository {
  /** Null when the user no longer exists. */
  autoSuggestEnabled(userId: string): Promise<boolean | null>;
  /** Newest first. */
  listMappings(userId: string): Promise<SuggestionMapping[]>;
  /** False when the row is not the user's. */
  deleteMapping(userId: string, id: string): Promise<boolean>;
  /** Returns how many rows were removed. */
  deleteAllMappings(userId: string): Promise<number>;
}
