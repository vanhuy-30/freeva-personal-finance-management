import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import type { Profile, ProfileRepository } from '../domain/profile.repository';

const select = {
  locale: true,
  defaultCurrencyCode: true,
  timezone: true,
  fiscalMonthStartDay: true,
  version: true,
};

@Injectable()
export class PrismaProfileRepository implements ProfileRepository {
  constructor(private readonly prisma: PrismaService) {}

  find(userId: string) {
    return this.prisma.user.findUnique({ where: { id: userId }, select });
  }

  currencies() {
    return this.prisma.currency.findMany({
      select: { code: true, minorDigits: true },
      orderBy: { code: 'asc' },
    });
  }

  async update(userId: string, profile: Profile): Promise<Profile | null> {
    const { version, ...fields } = profile;
    return this.prisma.$transaction(async (tx) => {
      const changed = await tx.user.updateMany({
        where: { id: userId, version },
        data: { ...fields, version: { increment: 1 } },
      });
      if (changed.count !== 1) return null;
      return tx.user.findUnique({ where: { id: userId }, select });
    });
  }
}
