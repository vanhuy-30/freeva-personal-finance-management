import { Controller, Get, Header, Param, Req, UseFilters, UseGuards } from '@nestjs/common';
import { AuthGuard, type AuthRequest } from '../auth/auth.guard';
import { GoalForecastParamsDto } from './spend-forecast.dto';
import { SpendForecastExceptionFilter } from './spend-forecast-exception.filter';
import { SpendForecastService } from './spend-forecast.service';

/** BE-P5-E06: spending projected to the end of the fiscal month (S.2 card, S.3 screen). */
@Controller('v1/spending-forecast')
@UseGuards(AuthGuard)
@UseFilters(SpendForecastExceptionFilter)
export class SpendForecastController {
  constructor(private readonly forecasts: SpendForecastService) {}

  @Get() @Header('Cache-Control', 'no-store')
  spending(@Req() request: AuthRequest) {
    return this.forecasts.spending(request.session.userId);
  }
}

/** BE-P5-E06: expected month a goal is reached at the recent contribution pace (T.1). */
@Controller('v1/goals')
@UseGuards(AuthGuard)
@UseFilters(SpendForecastExceptionFilter)
export class GoalForecastController {
  constructor(private readonly forecasts: SpendForecastService) {}

  @Get(':id/forecast') @Header('Cache-Control', 'no-store')
  goal(@Req() request: AuthRequest, @Param() params: GoalForecastParamsDto) {
    return this.forecasts.goal(request.session.userId, params.id);
  }
}
