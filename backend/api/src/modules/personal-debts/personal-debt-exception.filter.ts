import { ArgumentsHost, Catch, ExceptionFilter, HttpException } from '@nestjs/common';
import type { Response } from 'express';
import { ReportError } from '../reports/domain/report';
import { TransactionError } from '../transactions/domain/transaction-error';
import { PersonalDebtError } from './domain/personal-debt';

@Catch()
export class PersonalDebtExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost): void {
    const response = host.switchToHttp().getResponse<Response>();
    response.setHeader('Cache-Control', 'no-store');
    if (exception instanceof PersonalDebtError) {
      const status = {
        VALIDATION_ERROR: 400,
        DEBT_NOT_FOUND: 404,
        DEBT_CONFLICT: 409,
        DEBT_OVERPAYMENT: 422,
      }[exception.code];
      response.status(status).json({
        error: { code: exception.code, message: 'Debt request could not be completed', details: [] },
      });
      return;
    }
    if (
      (exception instanceof TransactionError && exception.code === 'VALIDATION_ERROR') ||
      (exception instanceof ReportError && exception.code === 'VALIDATION_ERROR')
    ) {
      response.status(400).json({
        error: { code: 'VALIDATION_ERROR', message: 'Debt request could not be completed', details: [] },
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
      error: { code: 'PERSONAL_DEBT_UNAVAILABLE', message: 'Debts are temporarily unavailable', details: [] },
    });
  }
}
