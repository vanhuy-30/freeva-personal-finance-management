import { ArgumentsHost, Catch, ExceptionFilter, HttpException } from '@nestjs/common';
import type { Response } from 'express';

@Catch()
export class InsightExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost): void {
    const response = host.switchToHttp().getResponse<Response>();
    response.setHeader('Cache-Control', 'no-store');
    if (exception instanceof HttpException) {
      const payload = exception.getResponse();
      response.status(exception.getStatus()).json(
        typeof payload === 'object' && payload !== null && 'error' in payload &&
          typeof payload.error === 'object' && payload.error !== null ? payload :
          { error: { code: 'VALIDATION_ERROR', message: 'Invalid request', details: [] } },
      );
      return;
    }
    // Amounts and merchants are private: never reflect or log database exceptions.
    response.status(503).json({ error: { code: 'INSIGHTS_UNAVAILABLE', message: 'Insights are temporarily unavailable', details: [] } });
  }
}
