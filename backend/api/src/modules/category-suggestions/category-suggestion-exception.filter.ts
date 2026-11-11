import { ArgumentsHost, Catch, ExceptionFilter, HttpException } from '@nestjs/common';
import type { Response } from 'express';
import { CategorySuggestionError } from './domain/category-suggestion';

@Catch()
export class CategorySuggestionExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost): void {
    const response = host.switchToHttp().getResponse<Response>();
    response.setHeader('Cache-Control', 'no-store');
    if (exception instanceof CategorySuggestionError) {
      response.status(404).json({ error: { code: exception.code, message: 'Suggestion request could not be completed', details: [] } });
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
    // Merchant names are private: never reflect or log database exceptions.
    response.status(503).json({ error: { code: 'SUGGESTIONS_UNAVAILABLE', message: 'Suggestions are temporarily unavailable', details: [] } });
  }
}
