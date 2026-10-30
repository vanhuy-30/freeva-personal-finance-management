import { importPKCS8, SignJWT } from 'jose';
import type { PushMessage, PushResult, PushSender } from '../domain/push-sender';
import type { PushSettings } from './push-settings';

const TOKEN_URL = 'https://oauth2.googleapis.com/token';
const SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';

type Fetch = typeof fetch;

/** FCM HTTP v1 over fetch + jose (no firebase-admin). Errors are mapped to a result, never thrown or logged with PII. */
export class FcmPushSender implements PushSender {
  readonly enabled = true;
  private access?: { value: string; expiresAt: number };

  constructor(
    private readonly settings: PushSettings,
    private readonly http: Fetch = fetch,
    private readonly clock: () => number = Date.now,
  ) {}

  async send(message: PushMessage): Promise<PushResult> {
    try {
      const bearer = await this.bearer();
      const response = await this.http(
        `https://fcm.googleapis.com/v1/projects/${this.settings.projectId}/messages:send`,
        {
          method: 'POST',
          headers: { authorization: `Bearer ${bearer}`, 'content-type': 'application/json' },
          body: JSON.stringify({
            message: {
              token: message.token,
              notification: { title: message.title, body: message.body },
              data: message.data,
              android: { priority: 'HIGH' },
              apns: { headers: { 'apns-priority': '10' }, payload: { aps: { sound: 'default' } } },
            },
          }),
        },
      );
      if (response.ok) return 'sent';
      if (response.status === 401) this.access = undefined;
      if (response.status === 404) return 'invalid_token';
      if (response.status === 400 && (await this.isInvalidArgument(response))) return 'invalid_token';
      return 'transient';
    } catch {
      return 'transient';
    }
  }

  private async isInvalidArgument(response: Response): Promise<boolean> {
    try {
      const body = (await response.json()) as { error?: { status?: string } };
      return body.error?.status === 'INVALID_ARGUMENT';
    } catch {
      return false;
    }
  }

  private async bearer(): Promise<string> {
    const now = this.clock();
    if (this.access && this.access.expiresAt - 60_000 > now) return this.access.value;
    const key = await importPKCS8(this.settings.privateKey, 'RS256');
    const seconds = Math.floor(now / 1000);
    const assertion = await new SignJWT({ scope: SCOPE })
      .setProtectedHeader({ alg: 'RS256', typ: 'JWT' })
      .setIssuer(this.settings.clientEmail)
      .setSubject(this.settings.clientEmail)
      .setAudience(TOKEN_URL)
      .setIssuedAt(seconds)
      .setExpirationTime(seconds + 3600)
      .sign(key);
    const response = await this.http(TOKEN_URL, {
      method: 'POST',
      headers: { 'content-type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion,
      }),
    });
    if (!response.ok) throw new Error('fcm_auth_failed');
    const json = (await response.json()) as { access_token?: string; expires_in?: number };
    if (!json.access_token) throw new Error('fcm_auth_failed');
    this.access = { value: json.access_token, expiresAt: now + (json.expires_in ?? 3600) * 1000 };
    return json.access_token;
  }
}

export class DisabledPushSender implements PushSender {
  readonly enabled = false;
  async send(): Promise<PushResult> {
    return 'transient';
  }
}
