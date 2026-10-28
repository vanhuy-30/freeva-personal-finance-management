import { ArgumentsHost, Catch, ExceptionFilter, HttpException } from '@nestjs/common';
import type { Response } from 'express';
import { BillError } from './domain/bill';

@Catch()
export class BillExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost): void {
    const response = host.switchToHttp().getResponse<Response>();
    response.setHeader('Cache-Control', 'no-store');
    if (exception instanceof BillError) {
      const status = {
        VALIDATION_ERROR: 400,
        BILL_NOT_FOUND: 404,
        BILL_CONFLICT: 409,
      }[exception.code];
      response.status(status).json({
        error: { code: exception.code, message: 'Bill request could not be completed', details: [] },
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
      error: { code: 'BILL_UNAVAILABLE', message: 'Bills are temporarily unavailable', details: [] },
    });
  }
}
