import { Inject, Injectable } from '@nestjs/common';
import { AppConfigReader } from '../app-config/app-config.reader';
import { AutoSuggestPolicy } from './auto-suggest.policy';
import {
  CATEGORY_SUGGESTION_REPOSITORY,
  CategorySuggestionError,
  merchantKey,
  type CategorySuggestionRepository,
  type SuggestSurface,
} from './domain/category-suggestion';
import { suggestCategory, type SuggestKind, type Suggestion, type SuggestionSource } from './domain/suggest';

export interface SuggestRequest { merchant?: string | null; note?: string | null; type: SuggestKind }
/** One import row the user saved, with what was suggested for it (if anything). */
export interface ImportOutcome { merchant: string | null; suggestion: { categoryId: string; source: SuggestionSource } | null; chosenCategoryId: string }
export interface FeedbackRequest {
  merchant?: string | null;
  suggestedCategoryId: string;
  chosenCategoryId: string;
  source: SuggestionSource;
  surface: SuggestSurface;
}

const utcDay = (now: Date) => new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));

@Injectable()
export class CategorySuggestionService {
  constructor(
    @Inject(CATEGORY_SUGGESTION_REPOSITORY) private readonly repository: CategorySuggestionRepository,
    private readonly policy: AutoSuggestPolicy,
    private readonly config: AppConfigReader,
  ) {}

  /** Null when there is nothing confident to say, the flag is off, or the user switched suggestions off. */
  async suggest(userId: string, input: SuggestRequest): Promise<Suggestion | null> {
    const merchant = input.merchant?.trim() || null;
    const note = merchant ? null : input.note?.trim() || null;
    if (!merchant && !note) return null;
    if (!(await this.policy.allows('category_suggest', userId))) return null;
    const historySize = await this.config.value('categorySuggest.historySize');
    const [remembered, history, categories, commonMerchants, minConfidencePercent] = await Promise.all([
      merchant ? this.repository.rememberedCategoryId(userId, merchantKey(merchant)) : Promise.resolve(null),
      this.repository.historyCategoryIds(userId, { merchant, note }, input.type, historySize),
      this.repository.categories(userId),
      this.config.value('categorySuggest.commonMerchants'),
      this.config.value('categorySuggest.minConfidencePercent'),
    ]);
    return suggestCategory({
      merchant, note, kind: input.type, rememberedCategoryId: remembered, history, categories, commonMerchants, minConfidencePercent,
    });
  }

  /**
   * BE-P5-E03 import: one suggestion per item, with a fixed number of queries for the whole file.
   * Empty when suggestions are off for the user.
   */
  async suggestMany(userId: string, items: SuggestRequest[]): Promise<Array<Suggestion | null>> {
    if (!items.length || !(await this.policy.allows('category_suggest', userId))) return items.map(() => null);
    const clean = items.map(item => {
      const merchant = item.merchant?.trim() || null;
      return { merchant, note: merchant ? null : item.note?.trim() || null, type: item.type };
    });
    const merchants = [...new Set(clean.flatMap(item => (item.merchant ? [item.merchant] : [])))];
    const notes = [...new Set(clean.flatMap(item => (item.note ? [item.note] : [])))];
    const limit = await this.config.value('categorySuggest.historySize');
    const [remembered, history, categories, commonMerchants, minConfidencePercent] = await Promise.all([
      this.repository.rememberedCategoryIdsByKey(userId, [...new Set(merchants.map(merchantKey))]),
      this.repository.historyByKeys(userId, merchants, notes, limit),
      this.repository.categories(userId),
      this.config.value('categorySuggest.commonMerchants'),
      this.config.value('categorySuggest.minConfidencePercent'),
    ]);
    return clean.map(item => {
      if (!item.merchant && !item.note) return null;
      const key = merchantKey(item.merchant ?? item.note!);
      return suggestCategory({
        merchant: item.merchant, note: item.note, kind: item.type,
        rememberedCategoryId: item.merchant ? remembered.get(key) ?? null : null,
        history: history.get(`${item.merchant ? 'merchant' : 'notes'}|${item.type}|${key}`) ?? [],
        categories, commonMerchants, minConfidencePercent,
      });
    });
  }

  /**
   * BE-P5-E03 import commit: count every suggested row as accepted or corrected, and remember each
   * merchant (once, last row wins) under the category the user kept — suggested or chosen in the sheet.
   * Best effort: the caller has already written the transactions.
   */
  async recordImport(userId: string, rows: ImportOutcome[], now = new Date()): Promise<void> {
    if (!rows.length || !(await this.policy.allows('category_suggest', userId))) return;
    const tally = new Map<string, number>();
    for (const row of rows) {
      if (!row.suggestion) continue;
      const outcome = row.chosenCategoryId === row.suggestion.categoryId ? 'accepted' : 'corrected';
      const key = `${row.suggestion.source}|${outcome}`;
      tally.set(key, (tally.get(key) ?? 0) + 1);
    }
    for (const [key, by] of tally) {
      const [source, outcome] = key.split('|') as [SuggestionSource, 'accepted' | 'corrected'];
      await this.repository.count(utcDay(now), 'import', source, outcome, by);
    }
    const last = new Map<string, { merchant: string; categoryId: string }>();
    for (const row of rows) {
      const merchant = row.merchant?.trim();
      if (merchant) last.set(merchantKey(merchant), { merchant, categoryId: row.chosenCategoryId });
    }
    for (const { merchant, categoryId } of last.values()) await this.repository.remember(userId, merchant, categoryId);
  }

  /**
   * The user saved after seeing a suggestion: count it as accepted or corrected and remember the
   * merchant under the category they chose. Ignored when suggestions are off for them.
   */
  async feedback(userId: string, input: FeedbackRequest, now = new Date()): Promise<void> {
    if (!(await this.policy.allows('category_suggest', userId))) return;
    const categories = await this.repository.categories(userId);
    if (!categories.some(c => c.id === input.chosenCategoryId)) throw new CategorySuggestionError('CATEGORY_NOT_FOUND');
    const outcome = input.chosenCategoryId === input.suggestedCategoryId ? 'accepted' : 'corrected';
    await this.repository.count(utcDay(now), input.surface, input.source, outcome);
    const merchant = input.merchant?.trim();
    if (merchant) await this.repository.remember(userId, merchant, input.chosenCategoryId);
  }

  async stats(from: Date, to: Date) {
    const rows = await this.repository.stats(from, to);
    const accepted = rows.reduce((sum, row) => sum + row.accepted, 0);
    const corrected = rows.reduce((sum, row) => sum + row.corrected, 0);
    const total = accepted + corrected;
    return {
      from: from.toISOString().slice(0, 10),
      to: to.toISOString().slice(0, 10),
      accepted,
      corrected,
      acceptRatePercent: total ? Math.round((accepted * 1000) / total) / 10 : null,
      rows,
    };
  }
}
