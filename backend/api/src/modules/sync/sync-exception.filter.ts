import { ArgumentsHost, Catch, ExceptionFilter, HttpException } from '@nestjs/common';
import type { Response } from 'express';
import { SyncError } from './domain/sync';

@Catch()
export class SyncExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost): void {
    const response = host.switchToHttp().getResponse<Response>();
    response.setHeader('Cache-Control', 'no-store');
    if (exception instanceof SyncError) {
      const status = { VALIDATION_ERROR: 400, SYNC_SCHEMA_MISMATCH: 409, SYNC_UNAVAILABLE: 503 }[exception.code];
      const message = exception.code === 'SYNC_UNAVAILABLE' ? 'Sync is temporarily unavailable' : 'Sync request could not be completed';
      response.status(status).json({ error: { code: exception.code, message, details: [] } });
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
    response.status(503).json({ error: { code: 'SYNC_UNAVAILABLE', message: 'Sync is temporarily unavailable', details: [] } });
  }
}
