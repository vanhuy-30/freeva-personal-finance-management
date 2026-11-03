import { ArgumentsHost, Catch, ExceptionFilter, HttpException } from '@nestjs/common';
import type { Response } from 'express';
import { TransactionImportError } from './domain/transaction-import';

@Catch()
export class TransactionImportExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost): void {
    const response = host.switchToHttp().getResponse<Response>();
    response.setHeader('Cache-Control', 'no-store');
    if (exception instanceof TransactionImportError) {
      const status = { VALIDATION_ERROR: 400, FILE_INVALID: 400, FILE_TOO_LARGE: 413, IMPORT_NOT_FOUND: 404, IMPORT_CONFLICT: 409 }[exception.code];
      response.status(status).json({ error: { code: exception.code, message: 'Import request could not be completed', details: [] } });
      return;
    }
    if (exception instanceof HttpException) {
      const payload = exception.getResponse();
      response.status(exception.getStatus()).json(
        typeof payload === 'object' && payload !== null && 'error' in payload && typeof payload.error === 'object' && payload.error !== null
          ? payload
          : { error: { code: 'VALIDATION_ERROR', message: 'Invalid request', details: [] } },
      );
      return;
    }
    response.status(503).json({ error: { code: 'IMPORT_UNAVAILABLE', message: 'Import is temporarily unavailable', details: [] } });
  }
}
