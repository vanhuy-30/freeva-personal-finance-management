import { ArgumentsHost, Catch } from '@nestjs/common';
import { BaseExceptionFilter } from '@nestjs/core';
import * as Sentry from '@sentry/nestjs';
import { shouldCaptureException } from './capture-policy';

@Catch()
export class SentryExceptionFilter extends BaseExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost): void {
    if (shouldCaptureException(exception)) {
      Sentry.captureException(exception);
    }
    super.catch(exception, host);
  }
}
