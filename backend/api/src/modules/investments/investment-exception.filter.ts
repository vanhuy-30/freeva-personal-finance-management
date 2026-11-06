import { ArgumentsHost, Catch, ExceptionFilter, HttpException } from '@nestjs/common';
import type { Response } from 'express';
import { ReportError } from '../reports/domain/report';
import { TransactionError } from '../transactions/domain/transaction-error';
import { InvestmentError } from './domain/investment';

@Catch()
export class InvestmentExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost): void {
    const response = host.switchToHttp().getResponse<Response>();
    response.setHeader('Cache-Control', 'no-store');
    if (exception instanceof InvestmentError) {
      const status = {
        VALIDATION_ERROR: 400,
        INVESTMENT_NOT_FOUND: 404,
        INVESTMENT_CONFLICT: 409,
        INVESTMENT_OVERSELL: 422,
        INVESTMENT_UNSUPPORTED: 422,
      }[exception.code];
      response.status(status).json({
        error: { code: exception.code, message: 'Investment request could not be completed', details: [] },
      });
      return;
    }
    if (
      (exception instanceof TransactionError && exception.code === 'VALIDATION_ERROR') ||
      (exception instanceof ReportError && exception.code === 'VALIDATION_ERROR')
    ) {
      response.status(400).json({
        error: { code: 'VALIDATION_ERROR', message: 'Investment request could not be completed', details: [] },
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
      error: { code: 'INVESTMENT_UNAVAILABLE', message: 'Investments are temporarily unavailable', details: [] },
    });
  }
}
