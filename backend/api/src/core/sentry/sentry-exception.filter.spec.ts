import {
  ArgumentsHost,
  BadRequestException,
  Logger,
  ServiceUnavailableException,
} from '@nestjs/common';
import * as Sentry from '@sentry/nestjs';
import { SentryExceptionFilter } from './sentry-exception.filter';

jest.mock('@sentry/nestjs', () => ({
  captureException: jest.fn(),
}));

describe('SentryExceptionFilter (INF-P1-001)', () => {
  const reply = jest.fn();
  const response = { locals: {} };
  const adapter = {
    reply,
    isHeadersSent: () => false,
    end: jest.fn(),
  };

  function host(): ArgumentsHost {
    return {
      getArgByIndex: (index: number) => (index === 1 ? response : undefined),
      switchToHttp: () => ({
        getResponse: () => response,
        getRequest: () => ({}),
        getNext: () => undefined,
      }),
      getArgs: () => [undefined, response],
      getType: () => 'http',
      switchToRpc: () => {
        throw new Error('unused');
      },
      switchToWs: () => {
        throw new Error('unused');
      },
    } as ArgumentsHost;
  }

  beforeEach(() => {
    reply.mockReset();
    jest.mocked(Sentry.captureException).mockReset();
    jest.spyOn(Logger.prototype, 'error').mockImplementation(() => undefined);
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  it('captures 5xx and keeps the HttpException body', () => {
    const body = {
      error: {
        code: 'DATABASE_UNAVAILABLE',
        message: 'Database is not reachable',
      },
    };
    const exception = new ServiceUnavailableException(body);
    const filter = new SentryExceptionFilter(adapter as never);
    filter.catch(exception, host());

    expect(Sentry.captureException).toHaveBeenCalledWith(exception);
    expect(reply).toHaveBeenCalledWith(response, body, 503);
  });

  it('reports unknown errors with the default 500 envelope', () => {
    const exception = new Error('boom');
    const filter = new SentryExceptionFilter(adapter as never);
    filter.catch(exception, host());

    expect(Sentry.captureException).toHaveBeenCalledWith(exception);
    expect(reply).toHaveBeenCalledWith(
      response,
      { statusCode: 500, message: 'Internal server error' },
      500,
    );
  });

  it('does not capture client errors', () => {
    const exception = new BadRequestException('invalid');
    const filter = new SentryExceptionFilter(adapter as never);
    filter.catch(exception, host());

    expect(Sentry.captureException).not.toHaveBeenCalled();
    expect(reply).toHaveBeenCalled();
  });
});
