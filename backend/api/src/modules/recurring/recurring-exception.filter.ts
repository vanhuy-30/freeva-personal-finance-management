import { ArgumentsHost, Catch, ExceptionFilter, HttpException } from '@nestjs/common';
import type { Response } from 'express';
import { TransactionError } from '../transactions/domain/transaction-error';
import { RecurringError } from './domain/recurring';

@Catch()
export class RecurringExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost): void {
    const response = host.switchToHttp().getResponse<Response>();
    response.setHeader('Cache-Control', 'no-store');
    if (exception instanceof RecurringError) {
      const status = {
        VALIDATION_ERROR: 400,
        RECURRING_NOT_FOUND: 404,
        RECURRING_CONFLICT: 409,
      }[exception.code];
      response.status(status).json({
        error: { code: exception.code, message: 'Recurring request could not be completed', details: [] },
      });
      return;
    }
    if (exception instanceof TransactionError && exception.code === 'VALIDATION_ERROR') {
      response.status(400).json({
        error: { code: 'VALIDATION_ERROR', message: 'Recurring request could not be completed', details: [] },
      });
      return;
    }
    if (exception instanceof HttpException) {
      const payload = exception.getResponse();
      response.status(exception.getStatus()).json(
        typeof payload === 'object' && payload !== null && 'error' in payload &&
          typeof payload.error === 'object' && payload.error !== null
          ? payload
          : { error: { code: 'VALIDATION_ERROR', message: 'Invalid request', details: [] } },
      );
      return;
    }
    response.status(503).json({
      error: { code: 'RECURRING_UNAVAILABLE', message: 'Recurring transactions are temporarily unavailable', details: [] },
    });
  }
}
