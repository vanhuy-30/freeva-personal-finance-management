import { Body, Controller, Get, INestApplication, Post, Req } from '@nestjs/common';
import type { Request } from 'express';
import { Test } from '@nestjs/testing';
import { IsString } from 'class-validator';
import { configureHttp, trustProxyHops } from './configure-http';

class EchoDto {
  @IsString() name!: string;
}

@Controller('v1')
class EchoController {
  @Post('echo') echo(@Body() body: EchoDto) {
    return body;
  }

  @Get('ip') ip(@Req() request: Request) {
    return { ip: request.ip };
  }

  @Post('transactions/import') importEcho(@Body() body: { text: string }) {
    return { length: body.text.length };
  }
}

describe('configureHttp JSON bodies (fix BE-P3-011)', () => {
  let app: INestApplication;
  let base: string;

  beforeAll(async () => {
    const module = await Test.createTestingModule({ controllers: [EchoController] }).compile();
    app = module.createNestApplication();
    app.setGlobalPrefix('api');
    configureHttp(app);
    await app.listen(0, '127.0.0.1');
    base = await app.getUrl();
  });

  afterAll(async () => {
    await app?.close();
  });

  const post = (path: string, body: unknown) => fetch(`${base}/api/v1/${path}`, {
    method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify(body),
  });

  it('parses JSON on ordinary routes', async () => {
    const response = await post('echo', { name: 'Work' });
    expect(response.status).toBe(201);
    expect(await response.json()).toEqual({ name: 'Work' });
  });

  it('keeps the 100 kb limit on ordinary routes and 2 MB on import', async () => {
    const big = 'x'.repeat(500_000);
    expect((await post('echo', { name: big })).status).toBe(413);
    const imported = await post('transactions/import', { text: big });
    expect(imported.status).toBe(201);
    expect(await imported.json()).toEqual({ length: big.length });
  });
});

describe('trust proxy hops (SEC-P6-002)', () => {
  it('parses 0-9 and rejects anything else', () => {
    expect(trustProxyHops(undefined)).toBe(0);
    expect(trustProxyHops('')).toBe(0);
    expect(trustProxyHops(' 1 ')).toBe(1);
    for (const bad of ['-1', '10', 'true', '1.5', 'loopback']) {
      expect(() => trustProxyHops(bad)).toThrow('TRUST_PROXY_HOPS');
    }
  });

  async function ipSeen(hops: string | undefined, forwarded: string): Promise<string> {
    const previous = process.env.TRUST_PROXY_HOPS;
    if (hops === undefined) delete process.env.TRUST_PROXY_HOPS;
    else process.env.TRUST_PROXY_HOPS = hops;
    const module = await Test.createTestingModule({ controllers: [EchoController] }).compile();
    const app = module.createNestApplication();
    app.setGlobalPrefix('api');
    try {
      configureHttp(app);
      await app.listen(0, '127.0.0.1');
      const response = await fetch(`${await app.getUrl()}/api/v1/ip`, {
        headers: { 'x-forwarded-for': forwarded },
      });
      return ((await response.json()) as { ip: string }).ip;
    } finally {
      await app.close();
      if (previous === undefined) delete process.env.TRUST_PROXY_HOPS;
      else process.env.TRUST_PROXY_HOPS = previous;
    }
  }

  it('ignores X-Forwarded-For by default', async () => {
    expect(await ipSeen(undefined, '203.0.113.9')).toMatch(/127\.0\.0\.1$/);
  });

  it('with one hop takes the address the proxy appended, not a spoofed one', async () => {
    // Client spoofs 198.51.100.1; the proxy appends the real client 203.0.113.9.
    expect(await ipSeen('1', '198.51.100.1, 203.0.113.9')).toBe('203.0.113.9');
  });
});
