export const PUSH_TOKEN_REPOSITORY = Symbol('PUSH_TOKEN_REPOSITORY');

export type PushPlatformName = 'ios' | 'android';

export type PendingPush = {
  id: string;
  userId: string;
  kind: string;
  titleKey: string;
  bodyKey: string;
  params: Record<string, string | number>;
  locale: string;
  timezone: string;
  quietHoursEnabled: boolean;
  quietStart: string;
  quietEnd: string;
};

export interface PushTokenRepository {
  /** Bind (or replace) the token of one session. A token seen on another session moves here. */
  upsert(input: { userId: string; sessionId: string; token: string; platform: PushPlatformName }): Promise<void>;
  removeBySession(sessionId: string): Promise<void>;
  removeByToken(token: string): Promise<void>;
  tokensForUser(userId: string): Promise<Array<{ token: string; platform: PushPlatformName }>>;
  /** Unread, unclaimed rows newer than `since`, with the user's locale and quiet window. */
  pending(userId: string | null, since: Date, limit: number): Promise<PendingPush[]>;
  /** Atomically claim a row; false when someone else already did or it was read meanwhile. */
  claim(id: string, now: Date): Promise<boolean>;
  release(id: string): Promise<void>;
}
