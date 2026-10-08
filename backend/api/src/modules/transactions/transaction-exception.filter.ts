import { ArgumentsHost, Catch, ExceptionFilter, HttpException } from '@nestjs/common';
import type { Response } from 'express';
import { TransactionError } from './domain/transaction';

@Catch()
export class TransactionExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost): void {
    const response = host.switchToHttp().getResponse<Response>();
    response.setHeader('Cache-Control', 'no-store');
    if (exception instanceof TransactionError) {
      const status = { VALIDATION_ERROR: 400, ACCOUNT_NOT_FOUND: 404, TRANSACTION_NOT_FOUND: 404, TRANSACTION_CONFLICT: 409 }[exception.code];
      response.status(status).json({ error: { code: exception.code, message: 'Transaction request could not be completed', details: [] } });
      return;
    }
    if (exception instanceof HttpException) {
      const payload = exception.getResponse();
      response.status(exception.getStatus()).json(
        typeof payload === 'object' && payload !== null && 'error' in payload &&
          typeof payload.error === 'object' && payload.error !== null ? payload :
          { error: { code: 'VALIDATION_ERROR', message: 'Invalid request', details: [] } },
      );
      return;
    }
    // Never reflect or log database exceptions: they may contain financial data.
    response.status(503).json({ error: { code: 'TRANSACTIONS_UNAVAILABLE', message: 'Transactions are temporarily unavailable', details: [] } });
  }
}
