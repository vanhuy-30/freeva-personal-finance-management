import { BadRequestException, Body, Controller, Get, Header, HttpCode, Post, Query, Req, UseFilters, UseGuards } from '@nestjs/common';
import { AuthGuard, type AuthRequest } from '../auth/auth.guard';
import { StaffAuthGuard } from '../staff-auth/staff-auth.guard';
import { CategorySuggestionExceptionFilter } from './category-suggestion-exception.filter';
import { SuggestCategoryDto, SuggestionFeedbackDto, SuggestionStatsQueryDto } from './category-suggestion.dto';
import { CategorySuggestionService } from './category-suggestion.service';

/** BE-P5-E03: guess a category while the user types, and learn from what they saved. */
@Controller('v1/category-suggestions')
@UseGuards(AuthGuard)
@UseFilters(CategorySuggestionExceptionFilter)
export class SuggestController {
  constructor(private readonly suggestions: CategorySuggestionService) {}

  /** Always 200: `suggestion` is null when there is nothing to say or suggestions are off. */
  @Post('suggest') @HttpCode(200) @Header('Cache-Control', 'no-store')
  async suggest(@Req() request: AuthRequest, @Body() body: SuggestCategoryDto) {
    return { suggestion: await this.suggestions.suggest(request.session.userId, body) };
  }

  @Post('feedback') @HttpCode(204) @Header('Cache-Control', 'no-store')
  async feedback(@Req() request: AuthRequest, @Body() body: SuggestionFeedbackDto): Promise<void> {
    await this.suggestions.feedback(request.session.userId, body);
  }
}

const MAX_STATS_DAYS = 366;

/** BE-P5-E03: accept / correct rates for staff. No user data. */
@Controller('admin/category-suggestions')
@UseGuards(StaffAuthGuard)
@UseFilters(CategorySuggestionExceptionFilter)
export class AdminSuggestController {
  constructor(private readonly suggestions: CategorySuggestionService) {}

  @Get('stats') @Header('Cache-Control', 'no-store')
  stats(@Query() query: SuggestionStatsQueryDto) {
    const from = new Date(`${query.from}T00:00:00Z`);
    const to = new Date(`${query.to}T00:00:00Z`);
    const days = (to.getTime() - from.getTime()) / 86_400_000;
    if (Number.isNaN(days) || days < 0 || days > MAX_STATS_DAYS) {
      throw new BadRequestException({ error: { code: 'VALIDATION_ERROR', message: 'from..to must be 0-366 days', details: [] } });
    }
    return this.suggestions.stats(from, to);
  }
}
