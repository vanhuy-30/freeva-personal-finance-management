import { ArgumentsHost, Catch, ExceptionFilter, HttpException } from '@nestjs/common';
import type { Response } from 'express';
import { AppConfigError, type AppConfigErrorCode } from './domain/app-config';

const STATUS: Record<AppConfigErrorCode, number> = {
  CONFIG_KEY_UNKNOWN: 404,
  CONFIG_VALUE_INVALID: 400,
  CONFIG_CONFLICT: 409,
};

const MESSAGE: Record<AppConfigErrorCode, string> = {
  CONFIG_KEY_UNKNOWN: 'Unknown flag or config key',
  CONFIG_VALUE_INVALID: 'Value does not fit this key',
  CONFIG_CONFLICT: 'This key was changed by someone else; reload and try again',
};

@Catch()
export class AppConfigExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost): void {
    const response = host.switchToHttp().getResponse<Response>();
    response.setHeader('Cache-Control', 'no-store');
    if (exception instanceof AppConfigError) {
      response.status(STATUS[exception.code]).json({
        error: {
          code: exception.code,
          message: MESSAGE[exception.code],
          details: exception.reason ? [{ reason: exception.reason }] : [],
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
    // Never reflect or log database exceptions.
    response.status(503).json({
      error: { code: 'APP_CONFIG_UNAVAILABLE', message: 'App config is temporarily unavailable', details: [] },
    });
  }
}
