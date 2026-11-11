import { Body, Controller, INestApplication, Post } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { IsString } from 'class-validator';
import { configureHttp } from './configure-http';

class EchoDto {
  @IsString() name!: string;
}

@Controller('v1')
class EchoController {
  @Post('echo') echo(@Body() body: EchoDto) {
    return body;
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
