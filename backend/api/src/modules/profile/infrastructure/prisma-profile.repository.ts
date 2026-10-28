import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import type { OnboardingAnswers, Profile, ProfileRepository, ProfileUpdate } from '../domain/profile.repository';

const select = {
  displayName: true,
  locale: true,
  defaultCurrencyCode: true,
  timezone: true,
  fiscalMonthStartDay: true,
  version: true,
  onboardingGoals: true,
};

function toProfile(row: { onboardingGoals: string[] } & Omit<Profile, 'goals'> | null): Profile | null {
  if (!row) return null;
  const { onboardingGoals, ...rest } = row;
  return { ...rest, goals: onboardingGoals };
}

@Injectable()
export class PrismaProfileRepository implements ProfileRepository {
  constructor(private readonly prisma: PrismaService) {}

  async find(userId: string) {
    return toProfile(await this.prisma.user.findUnique({ where: { id: userId }, select }));
  }

  currencies() {
    return this.prisma.currency.findMany({
      select: { code: true, minorDigits: true },
      orderBy: { code: 'asc' },
    });
  }

  async saveOnboarding(userId: string, answers: OnboardingAnswers): Promise<boolean> {
    const changed = await this.prisma.user.updateMany({
      where: { id: userId },
      data: {
        ...(answers.goals ? { onboardingGoals: answers.goals } : {}),
        ...(answers.trackingHabit ? { trackingHabit: answers.trackingHabit } : {}),
        ...(answers.reviewCadence ? { reviewCadence: answers.reviewCadence } : {}),
      },
    });
    return changed.count === 1;
  }

  async update(userId: string, profile: ProfileUpdate): Promise<Profile | null> {
    const { version, ...fields } = profile;
    return this.prisma.$transaction(async (tx) => {
      const changed = await tx.user.updateMany({
        where: { id: userId, version },
        data: { ...fields, version: { increment: 1 } },
      });
      if (changed.count !== 1) return null;
      return toProfile(await tx.user.findUnique({ where: { id: userId }, select }));
    });
  }
}
