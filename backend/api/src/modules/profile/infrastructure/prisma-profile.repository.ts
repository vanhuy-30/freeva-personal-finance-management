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
  trackingHabit: true,
  reviewCadence: true,
  onboardingBudgetMinor: true,
  displayCurrencyCode: true,
};

type Row = Omit<Profile, 'goals' | 'onboardingBudgetMinor'> & { onboardingGoals: string[]; onboardingBudgetMinor: bigint | null };

function toProfile(row: Row | null): Profile | null {
  if (!row) return null;
  const { onboardingGoals, onboardingBudgetMinor, ...rest } = row;
  return { ...rest, goals: onboardingGoals, onboardingBudgetMinor: onboardingBudgetMinor?.toString() ?? null };
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
        ...(answers.budgetMinor ? { onboardingBudgetMinor: BigInt(answers.budgetMinor) } : {}),
      },
    });
    return changed.count === 1;
  }

  async saveDisplayCurrency(userId: string, code: string | null): Promise<boolean> {
    const changed = await this.prisma.user.updateMany({ where: { id: userId }, data: { displayCurrencyCode: code } });
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
