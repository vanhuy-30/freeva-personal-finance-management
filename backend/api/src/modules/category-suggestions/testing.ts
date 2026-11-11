import type { CategorySuggestionRepository } from './domain/category-suggestion';

/** Jest fake of the repository; every method resolves to an empty answer unless overridden. */
export function repo(overrides: Partial<CategorySuggestionRepository> = {}): CategorySuggestionRepository {
  return {
    autoSuggestEnabled: jest.fn().mockResolvedValue(true),
    listMappings: jest.fn().mockResolvedValue([]),
    deleteMapping: jest.fn().mockResolvedValue(true),
    deleteAllMappings: jest.fn().mockResolvedValue(0),
    rememberedCategoryId: jest.fn().mockResolvedValue(null),
    historyCategoryIds: jest.fn().mockResolvedValue([]),
    categories: jest.fn().mockResolvedValue([]),
    remember: jest.fn().mockResolvedValue(undefined),
    count: jest.fn().mockResolvedValue(undefined),
    stats: jest.fn().mockResolvedValue([]),
    ...overrides,
  };
}
