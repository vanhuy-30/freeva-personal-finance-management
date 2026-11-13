import { Inject, Injectable } from '@nestjs/common';
import { AppConfigService } from '../app-config/app-config.service';
import type { FlagKey } from '../app-config/domain/app-config-registry';
import { CATEGORY_SUGGESTION_REPOSITORY, type CategorySuggestionRepository } from './domain/category-suggestion';

/** Flags that the user switch "Gợi ý tự động" covers. */
export type AutoSuggestFeature = Extract<FlagKey, 'category_suggest' | 'insights' | 'forecast'>;

/**
 * PRD-P5-E01: one answer for "may this user get suggestions?" — the server flag is on for them
 * AND they have not switched Gợi ý tự động off. BE-P5-E03/E04/E06 call this before computing
 * anything and return an empty result when it is false.
 */
@Injectable()
export class AutoSuggestPolicy {
  constructor(
    private readonly appConfig: AppConfigService,
    @Inject(CATEGORY_SUGGESTION_REPOSITORY) private readonly repository: CategorySuggestionRepository,
  ) {}

  async allows(feature: AutoSuggestFeature, userId: string): Promise<boolean> {
    if (!(await this.appConfig.isEnabled(feature, userId))) return false;
    return (await this.repository.autoSuggestEnabled(userId)) === true;
  }
}
