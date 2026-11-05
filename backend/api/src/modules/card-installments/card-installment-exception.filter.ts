import { ArgumentsHost, Catch, ExceptionFilter, HttpException } from '@nestjs/common';
import type { Response } from 'express';
import { RecurringCalendarError } from '../recurring/domain/calendar';
import { CardInstallmentError } from './domain/card-installment';

@Catch()
export class CardInstallmentExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost): void {
    const response = host.switchToHttp().getResponse<Response>();
    response.setHeader('Cache-Control', 'no-store');
    if (exception instanceof CardInstallmentError) {
      const status = { VALIDATION_ERROR: 400, PLAN_NOT_FOUND: 404, PLAN_CONFLICT: 409 }[exception.code];
      response.status(status).json({
        error: { code: exception.code, message: 'Installment request could not be completed', details: [] },
      });
      return;
    }
    if (exception instanceof RecurringCalendarError) {
      response.status(400).json({
        error: { code: 'VALIDATION_ERROR', message: 'Installment request could not be completed', details: [] },
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
      error: { code: 'INSTALLMENT_UNAVAILABLE', message: 'Installments are temporarily unavailable', details: [] },
    });
  }
}
