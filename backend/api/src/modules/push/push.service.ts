import { Inject, Injectable, Logger } from '@nestjs/common';
import { isInQuietHours } from '../notifications/domain/notification';
import { pushCopy } from './domain/push-copy';
import {
  PUSH_SENDER,
  type PushDispatcher,
  type PushSender,
} from './domain/push-sender';
import {
  PUSH_TOKEN_REPOSITORY,
  type PendingPush,
  type PushPlatformName,
  type PushTokenRepository,
} from './domain/push-token.repository';

/** Rows older than this are never pushed (a late token or long outage must not replay history). */
export const PUSH_WINDOW_MS = 24 * 60 * 60 * 1000;
const BATCH = 100;

@Injectable()
export class PushService implements PushDispatcher {
  private readonly logger = new Logger(PushService.name);

  constructor(
    @Inject(PUSH_TOKEN_REPOSITORY) private readonly tokens: PushTokenRepository,
    @Inject(PUSH_SENDER) private readonly sender: PushSender,
  ) {}

  register(input: { userId: string; sessionId: string; token: string; platform: PushPlatformName }) {
    return this.tokens.upsert(input);
  }

  unregister(sessionId: string) {
    return this.tokens.removeBySession(sessionId);
  }

  async drain(userId: string | null, now = new Date()): Promise<void> {
    if (!this.sender.enabled) return;
    const since = new Date(now.getTime() - PUSH_WINDOW_MS);
    const rows = await this.tokens.pending(userId, since, BATCH);
    let sent = 0;
    for (const row of rows) {
      try {
        if (await this.pushOne(row, now)) sent += 1;
      } catch (error) {
        const code = error instanceof Error ? error.name : 'unknown';
        this.logger.warn({ code }, 'push.row.failed');
      }
    }
    if (sent > 0) this.logger.log({ sent }, 'push.drain');
  }

  private async pushOne(row: PendingPush, now: Date): Promise<boolean> {
    // Quiet hours: leave the row unclaimed so it goes out once, after the window, if still unread.
    if (isInQuietHours(row, row.timezone, now)) return false;
    if (!(await this.tokens.claim(row.id, now))) return false;
    const targets = await this.tokens.tokensForUser(row.userId);
    if (targets.length === 0) return false;
    const copy = pushCopy(row.locale, row);
    let delivered = false;
    let retry = false;
    for (const target of targets) {
      const result = await this.sender.send({
        token: target.token,
        platform: target.platform,
        title: copy.title,
        body: copy.body,
        data: { notificationId: row.id, kind: row.kind },
      });
      if (result === 'sent') delivered = true;
      else if (result === 'invalid_token') await this.tokens.removeByToken(target.token);
      else retry = true;
    }
    if (!delivered && retry) await this.tokens.release(row.id);
    return delivered;
  }
}
