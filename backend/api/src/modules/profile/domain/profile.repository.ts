import { incomeBandMidpoint, type DeclaredIncomeBand } from './declared-income';

/** `maxMinor` null is the open top band; `midpointMinor` is the point used for suggestions. */
export type DeclaredIncomeView = { minMinor: string; maxMinor: string | null; midpointMinor: string };

export function declaredIncomeView(band: DeclaredIncomeBand | null): DeclaredIncomeView | null {
  if (!band) return null;
  return {
    minMinor: band.minMinor.toString(),
    maxMinor: band.maxMinor?.toString() ?? null,
    midpointMinor: incomeBandMidpoint(band).toString(),
  };
}

export interface Profile {
  /** Shown in greetings only. Null until the user sets it. */
  displayName: string | null;
  locale: string;
  defaultCurrencyCode: string;
  timezone: string;
  fiscalMonthStartDay: number;
  version: number;
  /** Onboarding goals (read only here; set via PATCH /profile/onboarding). */
  goals: string[];
  /**
   * BE-P6-002: income band the user declared (not actual income from transactions), minor units of the default
   * currency as strings; null until given. Not converted when the profile currency changes. Never logged.
   */
  declaredIncome: DeclaredIncomeView | null;
  /** Currency the Overview converts into (BE-P2-013). Null means the default currency. Set via PUT /profile/display-currency. */
  displayCurrencyCode: string | null;
  /** PRD-P5-E01: category suggestions, insights and spending forecast for this user. Set via PUT /profile/auto-suggest. */
  autoSuggestEnabled: boolean;
  /** When the profile photo last changed (ISO 8601); null without one. The photo itself is GET /profile/avatar. */
  avatarUpdatedAt: string | null;
}
/** `displayName` undefined keeps the stored value. */
export type ProfileUpdate = Omit<Profile, 'displayName' | 'goals' | 'declaredIncome' | 'displayCurrencyCode' | 'autoSuggestEnabled' | 'avatarUpdatedAt'> & { displayName?: string | null };
/** Only the fields present are stored; the rest keep their value. */
export interface OnboardingAnswers {
  goals?: string[];
  declaredIncome?: DeclaredIncomeBand;
}
/** `symbol` null means show the code (BE-P5-001). */
export interface CurrencyOption { code: string; minorDigits: number; symbol: string | null; isDefault: boolean; }
export const PROFILE_REPOSITORY = Symbol('PROFILE_REPOSITORY');
export interface ProfileRepository {
  find(userId: string): Promise<Profile | null>;
  currencies(): Promise<CurrencyOption[]>;
  update(userId: string, profile: ProfileUpdate): Promise<Profile | null>;
  saveOnboarding(userId: string, answers: OnboardingAnswers): Promise<boolean>;
  saveDeclaredIncome(userId: string, band: DeclaredIncomeBand | null): Promise<boolean>;
  saveDisplayCurrency(userId: string, code: string | null): Promise<boolean>;
  saveAutoSuggest(userId: string, enabled: boolean): Promise<boolean>;
  /** False when the user does not exist. */
  saveAvatar(userId: string, image: Buffer): Promise<boolean>;
  readAvatar(userId: string): Promise<{ image: Buffer; updatedAt: Date } | null>;
  deleteAvatar(userId: string): Promise<void>;
}
