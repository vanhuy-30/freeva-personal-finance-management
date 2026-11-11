import { Controller, Delete, Get, Header, HttpCode, Inject, Param, Req, UseFilters, UseGuards } from '@nestjs/common';
import { AuthGuard, type AuthRequest } from '../auth/auth.guard';
import { CategorySuggestionExceptionFilter } from './category-suggestion-exception.filter';
import { MappingIdDto } from './category-suggestion.dto';
import {
  CATEGORY_SUGGESTION_REPOSITORY, CategorySuggestionError, type CategorySuggestionRepository,
} from './domain/category-suggestion';

/**
 * PRD-P5-E01: merchants the app remembered, shown on Gợi ý tự động. Not behind a feature flag:
 * a user can always see and delete what was learned, even after the flag or the switch is off.
 */
@Controller('v1/category-suggestions/mappings')
@UseGuards(AuthGuard)
@UseFilters(CategorySuggestionExceptionFilter)
export class CategorySuggestionController {
  constructor(@Inject(CATEGORY_SUGGESTION_REPOSITORY) private readonly repository: CategorySuggestionRepository) {}

  @Get() @Header('Cache-Control', 'no-store')
  async list(@Req() request: AuthRequest) {
    const rows = await this.repository.listMappings(request.session.userId);
    return {
      items: rows.map(row => ({ id: row.id, merchant: row.merchant, category: row.category, updatedAt: row.updatedAt.toISOString() })),
      total: rows.length,
    };
  }

  @Delete(':id') @HttpCode(204) @Header('Cache-Control', 'no-store')
  async deleteOne(@Req() request: AuthRequest, @Param() params: MappingIdDto): Promise<void> {
    if (!(await this.repository.deleteMapping(request.session.userId, params.id))) {
      throw new CategorySuggestionError('MAPPING_NOT_FOUND');
    }
  }

  @Delete() @HttpCode(204) @Header('Cache-Control', 'no-store')
  async deleteAll(@Req() request: AuthRequest): Promise<void> {
    await this.repository.deleteAllMappings(request.session.userId);
  }
}
