import { Controller, Get, Header, Query, Req, UseFilters, UseGuards } from '@nestjs/common';
import { AuthGuard, type AuthRequest } from '../auth/auth.guard';
import { ForecastQueryDto } from './forecast.dto';
import { ForecastExceptionFilter } from './forecast-exception.filter';
import { ForecastService } from './forecast.service';

@Controller('v1/forecast')
@UseGuards(AuthGuard)
@UseFilters(ForecastExceptionFilter)
export class ForecastController {
  constructor(private readonly forecast: ForecastService) {}

  @Get() @Header('Cache-Control', 'no-store')
  get(@Req() req: AuthRequest, @Query() query: ForecastQueryDto) {
    return this.forecast.forecast(req.session.userId, query);
  }
}
