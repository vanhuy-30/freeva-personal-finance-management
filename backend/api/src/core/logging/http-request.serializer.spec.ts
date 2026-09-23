import pino from 'pino';
import { httpRequestSerializer } from './http-request.serializer';
import { pinoRedactOptions } from './pino-redact';

describe('auth HTTP logging', () => {
  it('drops raw URLs, query, headers and bodies, and redacts stored auth secrets', () => {
    const lines: string[] = [];
    const logger = pino(
      {
        serializers: { req: httpRequestSerializer },
        redact: pinoRedactOptions,
      },
      {
        write: (line) => {
          lines.push(line);
        },
      },
    );
    logger.info({
      req: {
        id: 'request-id',
        method: 'POST',
        url: '/api/v1/auth/verify-email?token=secret-query',
        query: { token: 'secret-query' },
        headers: { authorization: 'secret-bearer' },
        body: { email: 'private@example.test', password: 'secret-password' },
      },
      encryptedToken: 'secret-ciphertext',
      tokenHash: 'secret-hash',
    });
    expect(lines.join('')).not.toMatch(/secret-|private@example/);
    expect(JSON.parse(lines[0]).req.url).toBe('/api/v1/auth/verify-email');
  });
});
