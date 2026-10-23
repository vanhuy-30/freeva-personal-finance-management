import { Body, Controller, Header, HttpCode, Post, Req, UseFilters, UseGuards } from '@nestjs/common';
import { AuthGuard, type AuthRequest } from '../auth/auth.guard';
import { FEEDBACK_PER_HOUR, FEEDBACK_REPOSITORY, FeedbackError, type FeedbackRepository } from './domain/feedback';
import { CreateFeedbackDto } from './feedback.dto';
import { FeedbackExceptionFilter } from './feedback-exception.filter';
import { Inject } from '@nestjs/common';

@Controller('v1/feedback')
@UseGuards(AuthGuard)
@UseFilters(FeedbackExceptionFilter)
export class FeedbackController {
  constructor(@Inject(FEEDBACK_REPOSITORY) private readonly repository: FeedbackRepository) {}

  @Post() @HttpCode(204) @Header('Cache-Control', 'no-store')
  async create(@Req() request: AuthRequest, @Body() body: CreateFeedbackDto): Promise<void> {
    const stored = await this.repository.add(request.session.userId, body, FEEDBACK_PER_HOUR);
    if (!stored) throw new FeedbackError('RATE_LIMITED');
  }
}
