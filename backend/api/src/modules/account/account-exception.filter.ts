import { ArgumentsHost, Catch, ExceptionFilter, HttpException } from '@nestjs/common';
import type { Response } from 'express';
import { AccountPrivacyError } from './domain/account-privacy';

@Catch()
export class AccountExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost): void {
    const response = host.switchToHttp().getResponse<Response>();
    response.setHeader('Cache-Control', 'no-store');
    if (exception instanceof AccountPrivacyError) {
      const status = exception.code === 'SESSION_INVALID' ? 401 : 503;
      const message = status === 401 ? 'Invalid credentials' : 'Account request is temporarily unavailable';
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
    response.status(503).json({
      error: { code: 'ACCOUNT_UNAVAILABLE', message: 'Account request is temporarily unavailable', details: [] },
    });
  }
}
