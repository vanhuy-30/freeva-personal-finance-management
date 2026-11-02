import { ArgumentsHost, Catch, ExceptionFilter, HttpException } from '@nestjs/common';
import type { Response } from 'express';
import { ReportError } from '../reports/domain/report';
import { TransactionError } from '../transactions/domain/transaction-error';
import { GoalError } from './domain/goal';

@Catch()
export class GoalExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost): void {
    const response = host.switchToHttp().getResponse<Response>();
    response.setHeader('Cache-Control', 'no-store');
    if (exception instanceof GoalError) {
      const status = {
        VALIDATION_ERROR: 400,
        GOAL_NOT_FOUND: 404,
        GOAL_CONFLICT: 409,
        INSUFFICIENT_GOAL_BALANCE: 422,
      }[exception.code];
      response.status(status).json({
        error: { code: exception.code, message: 'Goal request could not be completed', details: [] },
      });
      return;
    }
    if (
      (exception instanceof TransactionError && exception.code === 'VALIDATION_ERROR') ||
      (exception instanceof ReportError && exception.code === 'VALIDATION_ERROR')
    ) {
      response.status(400).json({
        error: { code: 'VALIDATION_ERROR', message: 'Goal request could not be completed', details: [] },
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
      error: { code: 'GOAL_UNAVAILABLE', message: 'Goals are temporarily unavailable', details: [] },
    });
  }
}
