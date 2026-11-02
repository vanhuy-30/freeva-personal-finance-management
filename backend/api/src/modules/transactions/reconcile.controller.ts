import { Body, Controller, Header, Headers, Param, Post, Req, Res, UseFilters, UseGuards } from '@nestjs/common';
import type { Response } from 'express';
import { AuthGuard, type AuthRequest } from '../auth/auth.guard';
import { ReconcileDto, TransactionIdDto } from './transaction.dto';
import { TransactionService } from './transaction.service';
import { TransactionError } from './domain/transaction';
import { TransactionExceptionFilter } from './transaction-exception.filter';

/** BE-P3-005: wallet reconciliation lives under the wallet but writes a transaction. */
@Controller('v1/financial-accounts')
@UseGuards(AuthGuard)
@UseFilters(TransactionExceptionFilter)
export class ReconcileController {
  constructor(private readonly transactions: TransactionService) {}

  @Post(':id/reconcile') @Header('Cache-Control', 'no-store')
  async reconcile(@Req() request: AuthRequest, @Param() params: TransactionIdDto, @Body() body: ReconcileDto,
    @Headers('idempotency-key') key: string | undefined, @Res({ passthrough: true }) res: Response) {
    if (!key || key.toLowerCase() !== body.clientId) throw new TransactionError('VALIDATION_ERROR');
    const { result, created } = await this.transactions.reconcile(request.session.userId, params.id, body);
    res.status(created ? 201 : 200);
    return result;
  }
}
