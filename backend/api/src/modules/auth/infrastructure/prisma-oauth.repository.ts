import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import type {
  OAuthIdentity,
  OAuthProvider,
  OAuthRepository,
} from '../domain/oauth';

@Injectable()
export class PrismaOAuthRepository implements OAuthRepository {
  constructor(private readonly prisma: PrismaService) {}

  async createChallenge(
    provider: OAuthProvider,
    tokenHash: string,
    expiresAt: Date,
  ): Promise<void> {
    await this.prisma.oAuthChallenge.create({
      data: { provider, tokenHash, expiresAt },
    });
  }

  async hasChallenge(
    provider: OAuthProvider,
    tokenHash: string,
  ): Promise<boolean> {
    return !!(await this.prisma.oAuthChallenge.findFirst({
      where: { provider, tokenHash, expiresAt: { gt: new Date() } },
    }));
  }

  async login(
    identity: OAuthIdentity,
    challengeHash: string,
    tokenHash: string,
    expiresAt: Date,
  ) {
    // Retry unique collisions from concurrent first sign-ins; never merge by email.
    for (let attempt = 0; attempt < 2; attempt++) {
      try {
        return await this.prisma.$transaction(async (tx) => {
          const consumed = await tx.oAuthChallenge.deleteMany({
            where: {
              tokenHash: challengeHash,
              provider: identity.provider,
              expiresAt: { gt: new Date() },
            },
          });
          if (consumed.count !== 1) return null;
          const key = {
            provider: identity.provider,
            subject: identity.subject,
          };
          const existing = await tx.oAuthIdentity.findUnique({
            where: { provider_subject: key },
          });
          let userId = existing?.userId;
          if (!userId) {
            if (
              !identity.email ||
              (await tx.user.findUnique({
                where: { email: identity.email },
                select: { id: true },
              }))
            )
              return null;
            const user = await tx.user.create({
              data: {
                email: identity.email,
                emailVerifiedAt: new Date(),
                defaultCurrencyCode: 'VND',
                oauthIdentities: { create: key },
              },
            });
            userId = user.id;
            await tx.auditEvent.create({
              data: {
                actorType: 'user',
                actorId: userId,
                action: 'auth.oauth_register',
                targetType: 'user',
                targetId: userId,
                outcome: 'success',
              },
            });
          }
          // Same row lock as password reset and revoke: serialize session creation.
          await tx.$queryRaw`SELECT "id" FROM "User" WHERE "id" = ${userId}::uuid FOR UPDATE`;
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
              action: 'auth.oauth_login',
              targetType: 'session',
              targetId: session.id,
              outcome: 'success',
            },
          });
          return session;
        });
      } catch (error) {
        if (
          attempt === 0 &&
          error instanceof Prisma.PrismaClientKnownRequestError &&
          error.code === 'P2002'
        )
          continue;
        throw error;
      }
    }
    return null;
  }
}
