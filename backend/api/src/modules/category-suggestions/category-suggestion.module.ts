import { Module } from '@nestjs/common';
import { AppConfigModule } from '../app-config/app-config.module';
import { AuthModule } from '../auth/auth.module';
import { AutoSuggestPolicy } from './auto-suggest.policy';
import { CategorySuggestionController } from './category-suggestion.controller';
import { CategorySuggestionService } from './category-suggestion.service';
import { StaffAuthGuard } from '../staff-auth/staff-auth.guard';
import { AdminSuggestController, SuggestController } from './suggest.controller';
import { CATEGORY_SUGGESTION_REPOSITORY } from './domain/category-suggestion';
import { PrismaCategorySuggestionRepository } from './infrastructure/prisma-category-suggestion.repository';

@Module({
  imports: [AuthModule, AppConfigModule],
  controllers: [CategorySuggestionController, SuggestController, AdminSuggestController],
  providers: [AutoSuggestPolicy, CategorySuggestionService, StaffAuthGuard, { provide: CATEGORY_SUGGESTION_REPOSITORY, useClass: PrismaCategorySuggestionRepository }],
  exports: [AutoSuggestPolicy, CategorySuggestionService, CATEGORY_SUGGESTION_REPOSITORY],
})
export class CategorySuggestionModule {}
