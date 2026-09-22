import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
} from '@nestjs/common';
import type { Response } from 'express';

@Catch()
export class AuthExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost): void {
    const response = host.switchToHttp().getResponse<Response>();
    if (exception instanceof HttpException) {
      const payload = exception.getResponse();
      if (
        typeof payload === 'object' &&
        payload !== null &&
        'error' in payload &&
        typeof payload.error === 'object'
      ) {
        response.status(exception.getStatus()).json(payload);
        return;
      }
      response
        .status(exception.getStatus())
        .json({
          error: {
            code: 'VALIDATION_ERROR',
            message: 'Invalid request',
            details: [],
          },
        });
      return;
    }
    // Prisma/SMTP exceptions can contain PII and credentials; never return/log them.
    response
      .status(503)
      .json({
        error: {
          code: 'AUTH_UNAVAILABLE',
          message: 'Authentication is temporarily unavailable',
        },
      });
  }
}
