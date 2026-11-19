import { NEW_USER_CURRENCY_CODE } from '../../../core/money/currency';
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import { bandFromColumns, type DeclaredIncomeBand } from '../domain/declared-income';
import {
  declaredIncomeView, type OnboardingAnswers, type Profile, type ProfileRepository, type ProfileUpdate,
} from '../domain/profile.repository';

const select = {
  displayName: true,
  locale: true,
  defaultCurrencyCode: true,
  timezone: true,
  fiscalMonthStartDay: true,
  version: true,
  onboardingGoals: true,
  declaredIncomeMinMinor: true,
  declaredIncomeMaxMinor: true,
  displayCurrencyCode: true,
  autoSuggestEnabled: true,
};

type Row = Omit<Profile, 'goals' | 'declaredIncome'> & {
  onboardingGoals: string[]; declaredIncomeMinMinor: bigint | null; declaredIncomeMaxMinor: bigint | null;
};

function toProfile(row: Row | null): Profile | null {
  if (!row) return null;
  const { onboardingGoals, declaredIncomeMinMinor, declaredIncomeMaxMinor, ...rest } = row;
  return {
    ...rest,
    goals: onboardingGoals,
    declaredIncome: declaredIncomeView(bandFromColumns(declaredIncomeMinMinor, declaredIncomeMaxMinor)),
  };
}

function bandColumns(band: DeclaredIncomeBand | null) {
  return { declaredIncomeMinMinor: band?.minMinor ?? null, declaredIncomeMaxMinor: band?.maxMinor ?? null };
}

@Injectable()
export class PrismaProfileRepository implements ProfileRepository {
  constructor(private readonly prisma: PrismaService) {}

  async find(userId: string) {
    return toProfile(await this.prisma.user.findUnique({ where: { id: userId }, select }));
  }

  async currencies() {
    const rows = await this.prisma.currency.findMany({
      select: { code: true, minorDigits: true, symbol: true },
      orderBy: { code: 'asc' },
    });
    return rows.map((row) => ({ ...row, isDefault: row.code === NEW_USER_CURRENCY_CODE }));
  }

  async saveOnboarding(userId: string, answers: OnboardingAnswers): Promise<boolean> {
    const changed = await this.prisma.user.updateMany({
      where: { id: userId },
      data: {
        ...(answers.goals ? { onboardingGoals: answers.goals } : {}),
        ...(answers.declaredIncome ? bandColumns(answers.declaredIncome) : {}),
      },
    });
    return changed.count === 1;
  }

  async saveDeclaredIncome(userId: string, band: DeclaredIncomeBand | null): Promise<boolean> {
    const changed = await this.prisma.user.updateMany({ where: { id: userId }, data: bandColumns(band) });
    return changed.count === 1;
  }

  async saveDisplayCurrency(userId: string, code: string | null): Promise<boolean> {
    const changed = await this.prisma.user.updateMany({ where: { id: userId }, data: { displayCurrencyCode: code } });
    return changed.count === 1;
  }

  async saveAutoSuggest(userId: string, enabled: boolean): Promise<boolean> {
    const changed = await this.prisma.user.updateMany({ where: { id: userId }, data: { autoSuggestEnabled: enabled } });
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
