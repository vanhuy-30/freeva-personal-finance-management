import { Body, Controller, Delete, Get, Header, HttpCode, Param, Put, Req, UseFilters, UseGuards } from '@nestjs/common';
import { AuthGuard, type AuthRequest } from '../auth/auth.guard';
import { AuthExceptionFilter } from '../auth/auth-exception.filter';
import { FxRatePairParams, PutFxRateDto } from './fx-rate.dto';
import { FxRateService } from './fx-rate.service';

@Controller('v1/fx-rates')
@UseGuards(AuthGuard)
@UseFilters(AuthExceptionFilter)
export class FxRateController {
  constructor(private readonly rates: FxRateService) {}

  @Get() @Header('Cache-Control', 'no-store')
  list(@Req() request: AuthRequest) {
    return this.rates.list(request.session.userId);
  }

  @Put(':from/:to') @Header('Cache-Control', 'no-store')
  put(@Req() request: AuthRequest, @Param() pair: FxRatePairParams, @Body() body: PutFxRateDto) {
    return this.rates.put(request.session.userId, pair.from, pair.to, body);
  }

  @Delete(':from/:to') @HttpCode(204) @Header('Cache-Control', 'no-store')
  async remove(@Req() request: AuthRequest, @Param() pair: FxRatePairParams) {
    await this.rates.remove(request.session.userId, pair.from, pair.to);
  }
}
