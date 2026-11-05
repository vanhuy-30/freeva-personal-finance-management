import { Injectable } from '@nestjs/common';
import type { Prisma } from '@prisma/client';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import type {
  PendingPush,
  PushPlatformName,
  PushTokenRepository,
} from '../domain/push-token.repository';

function asParams(value: Prisma.JsonValue): Record<string, string | number> {
  if (value === null || typeof value !== 'object' || Array.isArray(value)) return {};
  const out: Record<string, string | number> = {};
  for (const [key, entry] of Object.entries(value)) {
    if (typeof entry === 'string' || typeof entry === 'number') out[key] = entry;
  }
  return out;
}

@Injectable()
export class PrismaPushTokenRepository implements PushTokenRepository {
  constructor(private readonly prisma: PrismaService) {}

  async upsert(input: {
    userId: string;
    sessionId: string;
    token: string;
    platform: PushPlatformName;
  }): Promise<void> {
    await this.prisma.$transaction(async tx => {
      // The same device token can belong to one session only (e.g. after logout and login as someone else).
      await tx.pushToken.deleteMany({
        where: { token: input.token, NOT: { sessionId: input.sessionId } },
      });
      await tx.pushToken.upsert({
        where: { sessionId: input.sessionId },
        create: input,
        update: { token: input.token, platform: input.platform },
      });
    });
  }

  async removeBySession(sessionId: string): Promise<void> {
    await this.prisma.pushToken.deleteMany({ where: { sessionId } });
  }

  async removeByToken(token: string): Promise<void> {
    await this.prisma.pushToken.deleteMany({ where: { token } });
  }

  async tokensForUser(userId: string) {
    const rows = await this.prisma.pushToken.findMany({
      where: { userId },
      select: { token: true, platform: true },
    });
    return rows.map(row => ({ token: row.token, platform: row.platform as PushPlatformName }));
  }

  async pending(userId: string | null, since: Date, limit: number): Promise<PendingPush[]> {
    const rows = await this.prisma.inAppNotification.findMany({
      where: {
        ...(userId ? { userId } : {}),
        pushedAt: null,
        readAt: null,
        createdAt: { gte: since },
        user: { pushTokens: { some: {} } },
      },
      orderBy: { createdAt: 'asc' },
      take: limit,
      include: {
        user: {
          select: {
            locale: true,
            timezone: true,
            notificationPreference: {
              select: { quietHoursEnabled: true, quietStart: true, quietEnd: true },
            },
          },
        },
      },
    });
    return rows.map(row => ({
      id: row.id,
      userId: row.userId,
      kind: row.kind,
      titleKey: row.titleKey,
      bodyKey: row.bodyKey,
      params: asParams(row.params),
      locale: row.user.locale,
      timezone: row.user.timezone,
      quietHoursEnabled: row.user.notificationPreference?.quietHoursEnabled ?? false,
      quietStart: row.user.notificationPreference?.quietStart ?? '22:00',
      quietEnd: row.user.notificationPreference?.quietEnd ?? '07:00',
    }));
  }

  async claim(id: string, now: Date): Promise<boolean> {
    const result = await this.prisma.inAppNotification.updateMany({
      where: { id, pushedAt: null, readAt: null },
      data: { pushedAt: now },
    });
    return result.count === 1;
  }

  async release(id: string): Promise<void> {
    await this.prisma.inAppNotification.updateMany({ where: { id }, data: { pushedAt: null } });
  }
}
