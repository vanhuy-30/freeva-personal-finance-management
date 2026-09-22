import { randomUUID } from 'node:crypto';
import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import type {
  AuthRepository,
  EmailChallenge,
  MailJob,
  TokenPurpose,
} from '../domain/auth.repository';

@Injectable()
export class PrismaAuthRepository implements AuthRepository {
  constructor(private readonly prisma: PrismaService) {}

  async register(
    email: string,
    passwordHash: string,
    challenge: EmailChallenge,
  ): Promise<void> {
    try {
      await this.prisma.$transaction(async (tx) => {
        const user = await tx.user.create({
          data: { email, passwordHash, defaultCurrencyCode: 'VND' },
        });
        await this.saveChallenge(tx, user.id, 'verify_email', challenge);
        await tx.auditEvent.create({
          data: {
            actorType: 'system',
            action: 'auth.register',
            targetType: 'user',
            targetId: user.id,
            outcome: 'success',
          },
        });
      });
    } catch (error) {
      // Registration never overwrites an existing user's password or verification state.
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002' &&
        Array.isArray(error.meta?.target) &&
        error.meta.target.includes('email')
      )
        return;
      throw error;
    }
  }

  findUser(email: string) {
    return this.prisma.user.findUnique({
      where: { email },
      select: {
        id: true,
        email: true,
        passwordHash: true,
        emailVerifiedAt: true,
      },
    });
  }

  async issueChallenge(
    email: string,
    purpose: TokenPurpose,
    challenge: EmailChallenge,
  ): Promise<void> {
    await this.prisma.$transaction(async (tx) => {
      const users = await tx.$queryRaw<
        {
          id: string;
          passwordHash: string | null;
          emailVerifiedAt: Date | null;
        }[]
      >`
        SELECT "id", "passwordHash", "emailVerifiedAt" FROM "User" WHERE "email" = ${email} FOR UPDATE`;
      const user = users[0];
      if (
        !user?.passwordHash ||
        (purpose === 'verify_email' && user.emailVerifiedAt)
      )
        return;
      await this.saveChallenge(tx, user.id, purpose, challenge);
    });
  }

  private async saveChallenge(
    tx: Prisma.TransactionClient,
    userId: string,
    purpose: TokenPurpose,
    challenge: EmailChallenge,
  ) {
    const { encryptedToken, ...token } = challenge;
    await tx.authToken.upsert({
      where: { userId_purpose: { userId, purpose } },
      create: { userId, purpose, ...token },
      update: token,
    });
    await tx.authMailJob.upsert({
      where: { userId_purpose: { userId, purpose } },
      create: { userId, purpose, encryptedToken, expiresAt: token.expiresAt },
      // New ID ensures an old worker cannot delete a newly queued message.
      update: {
        id: randomUUID(),
        encryptedToken,
        expiresAt: token.expiresAt,
        // Immediately eligible, independent of API/database clock skew.
        availableAt: new Date(0),
      },
    });
  }

  async consumeChallenge(
    tokenHash: string,
    purpose: TokenPurpose,
    passwordHash?: string,
  ): Promise<boolean> {
    return this.prisma.$transaction(async (tx) => {
      const token = await tx.authToken.findUnique({ where: { tokenHash } });
      if (!token || token.purpose !== purpose) return false;
      // All credential mutations and session creation serialize on the user row.
      await tx.$queryRaw`SELECT "id" FROM "User" WHERE "id" = ${token.userId}::uuid FOR UPDATE`;
      const consumed = await tx.authToken.deleteMany({
        where: {
          id: token.id,
          tokenHash,
          purpose,
          expiresAt: { gt: new Date() },
        },
      });
      if (consumed.count !== 1) return false;
      if (purpose === 'verify_email') {
        await tx.user.update({
          where: { id: token.userId },
          data: { emailVerifiedAt: new Date() },
        });
        await tx.authMailJob.deleteMany({
          where: { userId: token.userId, purpose },
        });
      } else {
        if (!passwordHash) throw new Error('Password hash required');
        await tx.user.update({
          where: { id: token.userId },
          data: { passwordHash },
        });
        await tx.authSession.deleteMany({ where: { userId: token.userId } });
        await tx.authToken.deleteMany({ where: { userId: token.userId } });
        await tx.authMailJob.deleteMany({ where: { userId: token.userId } });
      }
      await tx.auditEvent.create({
        data: {
          actorType: 'user',
          actorId: token.userId,
          action:
            purpose === 'verify_email'
              ? 'auth.verify_email'
              : 'auth.reset_password',
          targetType: 'user',
          targetId: token.userId,
          outcome: 'success',
        },
      });
      return true;
    });
  }

  async createSession(
    userId: string,
    passwordHash: string,
    tokenHash: string,
    expiresAt: Date,
  ) {
    return this.prisma.$transaction(async (tx) => {
      await tx.$queryRaw`SELECT "id" FROM "User" WHERE "id" = ${userId}::uuid FOR UPDATE`;
      const user = await tx.user.findUnique({ where: { id: userId } });
      if (!user?.passwordHash || user.passwordHash !== passwordHash)
        return null;
      const session = await tx.authSession.create({
        data: { userId, tokenHash, expiresAt },
        select: {
          id: true,
          userId: true,
          createdAt: true,
          expiresAt: true,
        },
      });
      await tx.auditEvent.create({
        data: {
          actorType: 'user',
          actorId: userId,
          action: 'auth.login',
          targetType: 'session',
          targetId: session.id,
          outcome: 'success',
        },
      });
      return session;
    });
  }

  findSession(tokenHash: string) {
    return this.prisma.authSession.findFirst({
      where: { tokenHash, expiresAt: { gt: new Date() } },
      select: {
        id: true,
        userId: true,
        createdAt: true,
        expiresAt: true,
      },
    });
  }

  listSessions(userId: string) {
    return this.prisma.authSession.findMany({
      where: { userId, expiresAt: { gt: new Date() } },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      select: { id: true, userId: true, createdAt: true, expiresAt: true },
    });
  }

  async revoke(userId: string, sessionId?: string): Promise<void> {
    await this.prisma.$transaction(async (tx) => {
      await tx.$queryRaw`SELECT "id" FROM "User" WHERE "id" = ${userId}::uuid FOR UPDATE`;
      const removed = await tx.authSession.deleteMany({
        where: { userId, ...(sessionId ? { id: sessionId } : {}) },
      });
      if (removed.count > 0) {
        await tx.auditEvent.create({
          data: {
            actorType: 'user',
            actorId: userId,
            action: sessionId
              ? 'auth.revoke_session'
              : 'auth.revoke_all_sessions',
            targetType: sessionId ? 'session' : 'user',
            targetId: sessionId ?? userId,
            outcome: 'success',
          },
        });
      }
    });
  }

  async takeRateLimit(
    key: string,
    limit: number,
    windowSeconds: number,
  ): Promise<number> {
    // One atomic statement shared by every API instance; DB time defines the window.
    const [row] = await this.prisma.$queryRaw<
      { count: number; retryAfter: number }[]
    >`
      INSERT INTO "AuthRateLimit" ("key", "count", "expiresAt")
      VALUES (${key}, 1, clock_timestamp() + ${windowSeconds} * interval '1 second')
      ON CONFLICT ("key") DO UPDATE SET
        "count" = CASE WHEN "AuthRateLimit"."expiresAt" <= clock_timestamp() THEN 1 ELSE LEAST("AuthRateLimit"."count" + 1, ${limit + 1}) END,
        "expiresAt" = CASE WHEN "AuthRateLimit"."expiresAt" <= clock_timestamp() THEN clock_timestamp() + ${windowSeconds} * interval '1 second' ELSE "AuthRateLimit"."expiresAt" END
      RETURNING "count", GREATEST(1, CEIL(EXTRACT(EPOCH FROM ("expiresAt" - clock_timestamp()))))::int AS "retryAfter"`;
    return row.count > limit ? row.retryAfter : 0;
  }

  async claimMail(): Promise<MailJob | null> {
    const rows = await this.prisma.$queryRaw<MailJob[]>`
      WITH next AS (
        SELECT "id" FROM "AuthMailJob" WHERE "availableAt" <= now() AND "expiresAt" > now()
        ORDER BY "availableAt" LIMIT 1 FOR UPDATE SKIP LOCKED
      ), claimed AS (
        UPDATE "AuthMailJob" SET "availableAt" = now() + interval '1 minute'
        WHERE "id" IN (SELECT "id" FROM next) RETURNING *
      ) SELECT claimed."id", "User"."email", claimed."purpose", claimed."encryptedToken"
        FROM claimed JOIN "User" ON "User"."id" = claimed."userId"`;
    return rows[0] ?? null;
  }

  async completeMail(id: string): Promise<void> {
    await this.prisma.authMailJob.deleteMany({ where: { id } });
  }

  async cleanup(): Promise<void> {
    const expiresAt = { lte: new Date() };
    await this.prisma.$transaction([
      this.prisma.authMailJob.deleteMany({ where: { expiresAt } }),
      this.prisma.authToken.deleteMany({ where: { expiresAt } }),
      this.prisma.authSession.deleteMany({ where: { expiresAt } }),
      this.prisma.authRateLimit.deleteMany({ where: { expiresAt } }),
    ]);
  }
}
