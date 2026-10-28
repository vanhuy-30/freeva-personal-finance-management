import { ArgumentsHost, Catch, ExceptionFilter, HttpException } from '@nestjs/common';
import type { Response } from 'express';
import { NotificationError } from './domain/notification';

@Catch()
export class NotificationExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost): void {
    const response = host.switchToHttp().getResponse<Response>();
    response.setHeader('Cache-Control', 'no-store');
    if (exception instanceof NotificationError) {
      const status = {
        VALIDATION_ERROR: 400,
        NOTIFICATION_NOT_FOUND: 404,
        NOTIFICATION_CONFLICT: 409,
        NOTIFICATION_SOURCE_UNAVAILABLE: 422,
      }[exception.code];
      response.status(status).json({
        error: {
          code: exception.code,
          message: 'Notification request could not be completed',
          details: [],
        },
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
      error: {
        code: 'NOTIFICATION_UNAVAILABLE',
        message: 'Notifications are temporarily unavailable',
        details: [],
      },
    });
  }
}
