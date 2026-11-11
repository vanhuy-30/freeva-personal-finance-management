import type { SuggestCategory, SuggestKind, SuggestionSource } from './suggest';

/** One merchant → category pair the user accepted (PRD-P5-E01; written by BE-P5-E03). */
export interface SuggestionMapping {
  id: string;
  merchant: string;
  category: { id: string; name: string; iconToken: string | null; colorToken: string | null };
  updatedAt: Date;
}

export class CategorySuggestionError extends Error {
  constructor(readonly code: 'MAPPING_NOT_FOUND' | 'CATEGORY_NOT_FOUND') { super(code); }
}

export const SUGGEST_SURFACES = ['entry', 'import'] as const;
export type SuggestSurface = (typeof SUGGEST_SURFACES)[number];
export const SUGGEST_SOURCES = ['remembered', 'history', 'common'] as const;
export type SuggestOutcome = 'accepted' | 'corrected';

export interface SuggestionStatRow {
  day: string;
  surface: SuggestSurface;
  source: SuggestionSource;
  accepted: number;
  corrected: number;
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
  /** BE-P5-E03: category id remembered for this merchant key, if any. */
  rememberedCategoryId(userId: string, key: string): Promise<string | null>;
  /**
   * Category ids of the user's latest live `kind` transactions whose merchant (else note) matches,
   * newest first, at most `limit`. Matching ignores case and extra spaces.
   */
  historyCategoryIds(userId: string, match: { merchant: string | null; note: string | null }, kind: SuggestKind, limit: number): Promise<string[]>;
  categories(userId: string): Promise<SuggestCategory[]>;
  /** Remembers (or moves) the merchant to the category. */
  remember(userId: string, merchant: string, categoryId: string): Promise<void>;
  /** Adds one to today's counter. */
  count(day: Date, surface: SuggestSurface, source: SuggestionSource, outcome: SuggestOutcome): Promise<void>;
  stats(from: Date, to: Date): Promise<SuggestionStatRow[]>;
}
