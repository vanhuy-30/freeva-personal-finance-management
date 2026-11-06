import {
  Body, Controller, Delete, Get, Header, HttpCode, Param, ParseUUIDPipe, Patch, Post, Query, Req, Res,
  UseFilters, UseGuards,
} from '@nestjs/common';
import type { Response } from 'express';
import { AuthGuard, type AuthRequest } from '../auth/auth.guard';
import { InvestmentExceptionFilter } from './investment-exception.filter';
import {
  AddInvestmentPriceDto, ArchiveInvestmentDto, CreateInvestmentDto, ListInvestmentsDto, TradeInvestmentDto, UpdateInvestmentDto,
} from './investment.dto';
import { InvestmentService } from './investment.service';

@Controller('v1/investments')
@UseGuards(AuthGuard)
@UseFilters(InvestmentExceptionFilter)
export class InvestmentController {
  constructor(private readonly investments: InvestmentService) {}

  @Get() @Header('Cache-Control', 'no-store')
  list(@Req() req: AuthRequest, @Query() query: ListInvestmentsDto) {
    return this.investments.list(req.session.userId, query.includeArchived);
  }

  @Get('summary') @Header('Cache-Control', 'no-store')
  summary(@Req() req: AuthRequest) {
    return this.investments.summary(req.session.userId);
  }

  @Post() @Header('Cache-Control', 'no-store')
  async create(@Req() req: AuthRequest, @Body() body: CreateInvestmentDto, @Res({ passthrough: true }) res: Response) {
    const result = await this.investments.create(req.session.userId, body);
    res.status(result.created ? 201 : 200);
    return result.investment;
  }

  @Get(':id') @Header('Cache-Control', 'no-store')
  find(@Req() req: AuthRequest, @Param('id', ParseUUIDPipe) id: string) {
    return this.investments.find(req.session.userId, id);
  }

  @Patch(':id') @Header('Cache-Control', 'no-store')
  update(@Req() req: AuthRequest, @Param('id', ParseUUIDPipe) id: string, @Body() body: UpdateInvestmentDto) {
    return this.investments.update(req.session.userId, id, body);
  }

  @Delete(':id') @HttpCode(204) @Header('Cache-Control', 'no-store')
  async archive(@Req() req: AuthRequest, @Param('id', ParseUUIDPipe) id: string, @Query() query: ArchiveInvestmentDto) {
    await this.investments.archive(req.session.userId, id, query.version);
  }

  @Get(':id/trades') @Header('Cache-Control', 'no-store')
  trades(@Req() req: AuthRequest, @Param('id', ParseUUIDPipe) id: string) {
    return this.investments.trades(req.session.userId, id);
  }

  @Post(':id/trades') @Header('Cache-Control', 'no-store')
  async trade(
    @Req() req: AuthRequest, @Param('id', ParseUUIDPipe) id: string, @Body() body: TradeInvestmentDto,
    @Res({ passthrough: true }) res: Response,
  ) {
    const result = await this.investments.trade(req.session.userId, id, body);
    res.status(result.created ? 201 : 200);
    return result.investment;
  }

  @Get(':id/prices') @Header('Cache-Control', 'no-store')
  prices(@Req() req: AuthRequest, @Param('id', ParseUUIDPipe) id: string) {
    return this.investments.prices(req.session.userId, id);
  }

  @Post(':id/prices') @Header('Cache-Control', 'no-store')
  async addPrice(
    @Req() req: AuthRequest, @Param('id', ParseUUIDPipe) id: string, @Body() body: AddInvestmentPriceDto,
    @Res({ passthrough: true }) res: Response,
  ) {
    const result = await this.investments.addPrice(req.session.userId, id, body);
    res.status(result.created ? 201 : 200);
    return result.investment;
  }
}
