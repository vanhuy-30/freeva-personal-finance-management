import { HttpException } from '@nestjs/common';

/** 4xx is handled by feature filters. Crash monitoring keeps 5xx and unknown errors. */
export function shouldCaptureException(exception: unknown): boolean {
  if (exception instanceof HttpException) {
    return exception.getStatus() >= 500;
  }
  return true;
}
