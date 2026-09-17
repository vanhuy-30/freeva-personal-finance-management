import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import type { UserAccountSummary } from '../domain/user-account-summary';
import type { UserLookupRepository } from '../domain/user-lookup.repository';

const userAccountSummarySelect = {
  id: true,
  email: true,
  locale: true,
  timezone: true,
  defaultCurrencyCode: true,
  fiscalMonthStartDay: true,
  createdAt: true,
} as const;

@Injectable()
export class PrismaUserLookupRepository implements UserLookupRepository {
  constructor(private readonly prisma: PrismaService) {}

  findById(userId: string): Promise<UserAccountSummary | null> {
    return this.prisma.user.findUnique({
      where: { id: userId },
      select: userAccountSummarySelect,
    });
  }

  findByEmail(email: string): Promise<UserAccountSummary | null> {
    return this.prisma.user.findUnique({
      where: { email },
      select: userAccountSummarySelect,
    });
  }
}
