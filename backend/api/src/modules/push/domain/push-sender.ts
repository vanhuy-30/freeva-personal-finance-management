/** Provider-neutral push port (FCM today). Payloads carry no balances, emails, rule names or session ids. */
export interface PushMessage {
  token: string;
  platform: 'ios' | 'android';
  title: string;
  body: string;
  /** String-only data the app uses to open the inbox. */
  data: Record<string, string>;
}

export type PushResult = 'sent' | 'invalid_token' | 'transient';

export const PUSH_SENDER = Symbol('PUSH_SENDER');

export interface PushSender {
  /** False when the provider is not configured; callers then skip sending. */
  readonly enabled: boolean;
  /** Never throws and never logs the token or message text. */
  send(message: PushMessage): Promise<PushResult>;
}

export const PUSH_DISPATCHER = Symbol('PUSH_DISPATCHER');

export interface PushDispatcher {
  /** Push unread inbox rows not yet claimed, for one user or everyone. Safe to call often. */
  drain(userId: string | null, now?: Date): Promise<void>;
}
