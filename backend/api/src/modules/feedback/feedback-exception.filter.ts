import { ArgumentsHost, Catch, ExceptionFilter, HttpException } from '@nestjs/common';
import type { Response } from 'express';
import { FeedbackError } from './domain/feedback';

@Catch()
export class FeedbackExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost): void {
    const response = host.switchToHttp().getResponse<Response>();
    response.setHeader('Cache-Control', 'no-store');
    if (exception instanceof FeedbackError) {
      response.setHeader('Retry-After', '3600');
      response.status(429).json({ error: { code: 'RATE_LIMITED', message: 'Too many messages. Try again later.', details: [] } });
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
    // The message is private: never reflect or log what the database says.
    response.status(503).json({ error: { code: 'FEEDBACK_UNAVAILABLE', message: 'Feedback is temporarily unavailable', details: [] } });
  }
}
