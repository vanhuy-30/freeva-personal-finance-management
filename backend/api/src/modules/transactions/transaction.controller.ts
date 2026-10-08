import { Body, Controller, Delete, Get, Header, Headers, HttpCode, Param, Patch, Post, Query, Req, Res, UseFilters, UseGuards } from '@nestjs/common';
import type { Response } from 'express';
import { AuthGuard, type AuthRequest } from '../auth/auth.guard';
import { TransactionIdDto, TransactionQueryDto, DeleteTransactionDto, CreateTransactionDto, UpdateTransactionDto } from './transaction.dto';
import { TransactionService } from './transaction.service';
import { TransactionError } from './domain/transaction';
import { TransactionExceptionFilter } from './transaction-exception.filter';

@Controller('v1/transactions')
@UseGuards(AuthGuard)
@UseFilters(TransactionExceptionFilter)
export class TransactionController {
  constructor(private readonly transactions: TransactionService) {}

  @Post() @Header('Cache-Control', 'no-store')
  async create(@Req() request: AuthRequest, @Body() body: CreateTransactionDto, @Headers('idempotency-key') key: string | undefined, @Res({ passthrough: true }) res: Response) {
    if (!key || key.toLowerCase() !== body.legs[0].clientId) throw new TransactionError('VALIDATION_ERROR');
    const result = await this.transactions.create(request.session.userId, body);
    res.status(result.created ? 201 : 200);
    return result.transaction;
  }
  @Get() @Header('Cache-Control', 'no-store')
  list(@Req() request: AuthRequest, @Query() query: TransactionQueryDto) {
    return this.transactions.list(request.session.userId, query);
  }
  @Get(':id') @Header('Cache-Control', 'no-store')
  find(@Req() request: AuthRequest, @Param() params: TransactionIdDto) {
    return this.transactions.find(request.session.userId, params.id);
  }
  @Patch(':id') @Header('Cache-Control', 'no-store')
  update(@Req() request: AuthRequest, @Param() params: TransactionIdDto, @Body() body: UpdateTransactionDto) {
    return this.transactions.update(request.session.userId, params.id, body);
  }
  @Delete(':id') @HttpCode(204) @Header('Cache-Control', 'no-store')
  delete(@Req() request: AuthRequest, @Param() params: TransactionIdDto, @Query() query: DeleteTransactionDto) {
    return this.transactions.delete(request.session.userId, params.id, query.version);
  }
}
