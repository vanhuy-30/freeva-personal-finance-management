import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import type { FeedbackInput, FeedbackRepository } from '../domain/feedback';

@Injectable()
export class PrismaFeedbackRepository implements FeedbackRepository {
  constructor(private readonly prisma: PrismaService) {}

  add(userId: string, input: FeedbackInput, limit: number): Promise<boolean> {
    return this.prisma.$transaction(async tx => {
      // Serialises one user's submissions so the limit cannot be raced.
      await tx.$queryRaw`SELECT "id" FROM "User" WHERE "id" = ${userId}::uuid FOR UPDATE`;
      const recent = await tx.feedback.count({ where: { userId, createdAt: { gt: new Date(Date.now() - 3_600_000) } } });
      if (recent >= limit) return false;
      await tx.feedback.create({ data: { userId, ...input } });
      return true;
    }, { isolationLevel: Prisma.TransactionIsolationLevel.ReadCommitted });
  }
}
