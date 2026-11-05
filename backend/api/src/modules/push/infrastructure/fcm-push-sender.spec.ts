import { generateKeyPairSync } from 'node:crypto';
import { FcmPushSender } from './fcm-push-sender';
import { readPushSettings } from './push-settings';
import { ConfigService } from '@nestjs/config';

const { privateKey } = generateKeyPairSync('rsa', {
  modulusLength: 2048,
  privateKeyEncoding: { type: 'pkcs8', format: 'pem' },
  publicKeyEncoding: { type: 'spki', format: 'pem' },
});
const settings = { projectId: 'demo', clientEmail: 'svc@demo.iam.gserviceaccount.com', privateKey };
const message = {
  token: 'secret-device-token-123456',
  platform: 'android' as const,
  title: 't',
  body: 'b',
  data: { notificationId: 'n1' },
};

function http(sendStatus: number, sendBody: unknown = {}) {
  return jest.fn(async (url: string | URL | Request) => {
    if (String(url).includes('oauth2')) {
      return new Response(JSON.stringify({ access_token: 'at', expires_in: 3600 }), { status: 200 });
    }
    return new Response(JSON.stringify(sendBody), { status: sendStatus });
  }) as unknown as typeof fetch & jest.Mock;
}

describe('BE-P2-015 FCM sender', () => {
  it('returns sent and reuses the cached access token', async () => {
    const fetcher = http(200);
    const sender = new FcmPushSender(settings, fetcher);
    await expect(sender.send(message)).resolves.toBe('sent');
    await expect(sender.send(message)).resolves.toBe('sent');
    const oauthCalls = fetcher.mock.calls.filter(call => String(call[0]).includes('oauth2'));
    expect(oauthCalls).toHaveLength(1);
  });

  it('maps UNREGISTERED (404) and INVALID_ARGUMENT (400) to invalid_token', async () => {
    await expect(new FcmPushSender(settings, http(404)).send(message)).resolves.toBe('invalid_token');
    await expect(
      new FcmPushSender(settings, http(400, { error: { status: 'INVALID_ARGUMENT' } })).send(message),
    ).resolves.toBe('invalid_token');
  });

  it('maps server and network errors to transient without throwing', async () => {
    await expect(new FcmPushSender(settings, http(503)).send(message)).resolves.toBe('transient');
    const broken = jest.fn().mockRejectedValue(new Error('boom secret-device-token-123456'));
    await expect(new FcmPushSender(settings, broken as unknown as typeof fetch).send(message)).resolves.toBe('transient');
  });
});

describe('BE-P2-015 push settings', () => {
  const cfg = (values: Record<string, string>) => new ConfigService(values);
  it('is off without a service account', () => {
    expect(readPushSettings(cfg({}))).toBeNull();
  });
  it('reads base64 JSON', () => {
    const json = JSON.stringify({ project_id: 'p', client_email: 'e', private_key: 'k' });
    expect(readPushSettings(cfg({ FCM_SERVICE_ACCOUNT_BASE64: Buffer.from(json).toString('base64') })))
      .toEqual({ projectId: 'p', clientEmail: 'e', privateKey: 'k' });
  });
  it('rejects incomplete accounts without echoing them', () => {
    expect(() => readPushSettings(cfg({ FCM_SERVICE_ACCOUNT_JSON: '{"project_id":"p"}' })))
      .toThrow('FCM service account must include');
  });
});
