import { ConfigService } from '@nestjs/config';

export interface PushSettings {
  projectId: string;
  clientEmail: string;
  privateKey: string;
}

/** Null when FCM is not configured; push then stays off (like Sentry without a DSN). */
export function readPushSettings(config: ConfigService): PushSettings | null {
  const raw = config.get<string>('FCM_SERVICE_ACCOUNT_JSON')?.trim();
  const encoded = config.get<string>('FCM_SERVICE_ACCOUNT_BASE64')?.trim();
  if (!raw && !encoded) return null;
  let parsed: unknown;
  try {
    parsed = JSON.parse(raw ?? Buffer.from(encoded as string, 'base64').toString('utf8'));
  } catch {
    throw new Error('FCM service account is not valid JSON');
  }
  const value = parsed as Record<string, unknown>;
  const projectId = value.project_id;
  const clientEmail = value.client_email;
  const privateKey = value.private_key;
  if (
    typeof projectId !== 'string' || !projectId ||
    typeof clientEmail !== 'string' || !clientEmail ||
    typeof privateKey !== 'string' || !privateKey
  ) {
    throw new Error('FCM service account must include project_id, client_email and private_key');
  }
  return { projectId, clientEmail, privateKey };
}
