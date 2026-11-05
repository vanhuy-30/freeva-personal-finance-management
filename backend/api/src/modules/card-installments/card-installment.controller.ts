import {
  Body, Controller, Get, Header, HttpCode, Param, ParseUUIDPipe, Post, Query, Req, Res, UseFilters, UseGuards,
} from '@nestjs/common';
import type { Response } from 'express';
import { AuthGuard, type AuthRequest } from '../auth/auth.guard';
import { CardInstallmentExceptionFilter } from './card-installment-exception.filter';
import {
  CardInstallmentDueDto, CloseCardInstallmentDto, CreateCardInstallmentDto, ListCardInstallmentsDto, PreviewCardInstallmentDto,
} from './card-installment.dto';
import { CardInstallmentService } from './card-installment.service';

@Controller('v1/card-installments')
@UseGuards(AuthGuard)
@UseFilters(CardInstallmentExceptionFilter)
export class CardInstallmentController {
  constructor(private readonly plans: CardInstallmentService) {}

  @Get() @Header('Cache-Control', 'no-store')
  list(@Req() req: AuthRequest, @Query() query: ListCardInstallmentsDto) {
    return this.plans.list(req.session.userId, query);
  }

  @Get('due') @Header('Cache-Control', 'no-store')
  due(@Req() req: AuthRequest, @Query() query: CardInstallmentDueDto) {
    return this.plans.due(req.session.userId, query);
  }

  @Post() @Header('Cache-Control', 'no-store')
  async create(@Req() req: AuthRequest, @Body() body: CreateCardInstallmentDto, @Res({ passthrough: true }) res: Response) {
    const result = await this.plans.create(req.session.userId, body);
    res.status(result.created ? 201 : 200);
    return result.plan;
  }

  @Post('preview') @HttpCode(200) @Header('Cache-Control', 'no-store')
  preview(@Req() req: AuthRequest, @Body() body: PreviewCardInstallmentDto) {
    return this.plans.preview(req.session.userId, body);
  }

  @Get(':id') @Header('Cache-Control', 'no-store')
  find(@Req() req: AuthRequest, @Param('id', ParseUUIDPipe) id: string) {
    return this.plans.find(req.session.userId, id);
  }

  @Post(':id/close') @HttpCode(200) @Header('Cache-Control', 'no-store')
  close(@Req() req: AuthRequest, @Param('id', ParseUUIDPipe) id: string, @Body() body: CloseCardInstallmentDto) {
    return this.plans.close(req.session.userId, id, body.version);
  }
}
