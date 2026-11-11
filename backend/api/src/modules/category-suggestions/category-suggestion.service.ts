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
