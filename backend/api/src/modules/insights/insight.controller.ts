import { Controller, Get, Header, Req, UseFilters, UseGuards } from '@nestjs/common';
import { AuthGuard, type AuthRequest } from '../auth/auth.guard';
import { InsightExceptionFilter } from './insight-exception.filter';
import { InsightService } from './insight.service';

/** BE-P5-E04: what is worth noticing in the current fiscal month. */
@Controller('v1/insights')
@UseGuards(AuthGuard)
@UseFilters(InsightExceptionFilter)
export class InsightController {
  constructor(private readonly insights: InsightService) {}

  @Get() @Header('Cache-Control', 'no-store')
  list(@Req() request: AuthRequest) {
    return this.insights.list(request.session.userId);
  }
}
