import {
  Body, Controller, Delete, Get, Header, HttpCode, Param, ParseUUIDPipe, Patch, Post, Query, Req, Res,
  UseFilters, UseGuards,
} from '@nestjs/common';
import type { Response } from 'express';
import { AuthGuard, type AuthRequest } from '../auth/auth.guard';
import { LoanExceptionFilter } from './loan-exception.filter';
import { AdjustLoanDto, ArchiveLoanDto, CreateLoanDto, ListLoansDto, PayLoanDto, UpdateLoanDto } from './loan.dto';
import { LoanService } from './loan.service';

@Controller('v1/loans')
@UseGuards(AuthGuard)
@UseFilters(LoanExceptionFilter)
export class LoanController {
  constructor(private readonly loans: LoanService) {}

  @Get() @Header('Cache-Control', 'no-store')
  list(@Req() req: AuthRequest, @Query() query: ListLoansDto) {
    return this.loans.list(req.session.userId, query.includeArchived);
  }

  @Get('summary') @Header('Cache-Control', 'no-store')
  summary(@Req() req: AuthRequest) {
    return this.loans.summary(req.session.userId);
  }

  @Post() @Header('Cache-Control', 'no-store')
  async create(@Req() req: AuthRequest, @Body() body: CreateLoanDto, @Res({ passthrough: true }) res: Response) {
    const result = await this.loans.create(req.session.userId, body);
    res.status(result.created ? 201 : 200);
    return result.loan;
  }

  @Get(':id') @Header('Cache-Control', 'no-store')
  find(@Req() req: AuthRequest, @Param('id', ParseUUIDPipe) id: string) {
    return this.loans.find(req.session.userId, id);
  }

  @Patch(':id') @Header('Cache-Control', 'no-store')
  update(@Req() req: AuthRequest, @Param('id', ParseUUIDPipe) id: string, @Body() body: UpdateLoanDto) {
    return this.loans.update(req.session.userId, id, body);
  }

  @Delete(':id') @HttpCode(204) @Header('Cache-Control', 'no-store')
  async archive(@Req() req: AuthRequest, @Param('id', ParseUUIDPipe) id: string, @Query() query: ArchiveLoanDto) {
    await this.loans.archive(req.session.userId, id, query.version);
  }

  @Get(':id/schedule') @Header('Cache-Control', 'no-store')
  schedule(@Req() req: AuthRequest, @Param('id', ParseUUIDPipe) id: string) {
    return this.loans.schedule(req.session.userId, id);
  }

  @Get(':id/payments') @Header('Cache-Control', 'no-store')
  payments(@Req() req: AuthRequest, @Param('id', ParseUUIDPipe) id: string) {
    return this.loans.payments(req.session.userId, id);
  }

  @Post(':id/payments') @Header('Cache-Control', 'no-store')
  async pay(
    @Req() req: AuthRequest, @Param('id', ParseUUIDPipe) id: string, @Body() body: PayLoanDto,
    @Res({ passthrough: true }) res: Response,
  ) {
    const result = await this.loans.pay(req.session.userId, id, body);
    res.status(result.created ? 201 : 200);
    return result.loan;
  }

  @Post(':id/adjust') @HttpCode(200) @Header('Cache-Control', 'no-store')
  adjust(@Req() req: AuthRequest, @Param('id', ParseUUIDPipe) id: string, @Body() body: AdjustLoanDto) {
    return this.loans.adjust(req.session.userId, id, body);
  }
}
