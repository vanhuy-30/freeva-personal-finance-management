import {
  Body, Controller, Delete, Get, Header, HttpCode, Param, ParseUUIDPipe, Patch, Post, Query, Req, Res,
  UseFilters, UseGuards,
} from '@nestjs/common';
import type { Response } from 'express';
import { AuthGuard, type AuthRequest } from '../auth/auth.guard';
import { PersonalDebtExceptionFilter } from './personal-debt-exception.filter';
import {
  ArchivePersonalDebtDto, CreatePersonalDebtDto, ListPersonalDebtsDto, PayPersonalDebtDto, UpdatePersonalDebtDto,
} from './personal-debt.dto';
import { PersonalDebtService } from './personal-debt.service';

@Controller('v1/personal-debts')
@UseGuards(AuthGuard)
@UseFilters(PersonalDebtExceptionFilter)
export class PersonalDebtController {
  constructor(private readonly debts: PersonalDebtService) {}

  @Get() @Header('Cache-Control', 'no-store')
  list(@Req() req: AuthRequest, @Query() query: ListPersonalDebtsDto) {
    return this.debts.list(req.session.userId, query.includeArchived);
  }

  @Get('summary') @Header('Cache-Control', 'no-store')
  summary(@Req() req: AuthRequest) {
    return this.debts.summary(req.session.userId);
  }

  @Post() @Header('Cache-Control', 'no-store')
  async create(@Req() req: AuthRequest, @Body() body: CreatePersonalDebtDto, @Res({ passthrough: true }) res: Response) {
    const result = await this.debts.create(req.session.userId, body);
    res.status(result.created ? 201 : 200);
    return result.debt;
  }

  @Get(':id') @Header('Cache-Control', 'no-store')
  find(@Req() req: AuthRequest, @Param('id', ParseUUIDPipe) id: string) {
    return this.debts.find(req.session.userId, id);
  }

  @Patch(':id') @Header('Cache-Control', 'no-store')
  update(@Req() req: AuthRequest, @Param('id', ParseUUIDPipe) id: string, @Body() body: UpdatePersonalDebtDto) {
    return this.debts.update(req.session.userId, id, body);
  }

  @Delete(':id') @HttpCode(204) @Header('Cache-Control', 'no-store')
  async archive(@Req() req: AuthRequest, @Param('id', ParseUUIDPipe) id: string, @Query() query: ArchivePersonalDebtDto) {
    await this.debts.archive(req.session.userId, id, query.version);
  }

  @Get(':id/payments') @Header('Cache-Control', 'no-store')
  payments(@Req() req: AuthRequest, @Param('id', ParseUUIDPipe) id: string) {
    return this.debts.payments(req.session.userId, id);
  }

  @Post(':id/payments') @Header('Cache-Control', 'no-store')
  async pay(
    @Req() req: AuthRequest, @Param('id', ParseUUIDPipe) id: string, @Body() body: PayPersonalDebtDto,
    @Res({ passthrough: true }) res: Response,
  ) {
    const result = await this.debts.pay(req.session.userId, id, body);
    res.status(result.created ? 201 : 200);
    return result.debt;
  }
}
