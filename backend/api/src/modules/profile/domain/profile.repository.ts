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
  /** Minor units as a string; null until typed. Not converted when the profile currency changes. Never logged. */
  monthlyIncomeMinor: string | null;
  /** Currency the Overview converts into (BE-P2-013). Null means the default currency. Set via PUT /profile/display-currency. */
  displayCurrencyCode: string | null;
  /** PRD-P5-E01: category suggestions, insights and spending forecast for this user. Set via PUT /profile/auto-suggest. */
  autoSuggestEnabled: boolean;
}
/** `displayName` undefined keeps the stored value. */
export type ProfileUpdate = Omit<Profile, 'displayName' | 'goals' | 'monthlyIncomeMinor' | 'displayCurrencyCode' | 'autoSuggestEnabled'> & { displayName?: string | null };
/** Only the fields present are stored; the rest keep their value. */
export interface OnboardingAnswers {
  goals?: string[];
  monthlyIncomeMinor?: string;
}
/** `symbol` null means show the code (BE-P5-001). */
export interface CurrencyOption { code: string; minorDigits: number; symbol: string | null; isDefault: boolean; }
export const PROFILE_REPOSITORY = Symbol('PROFILE_REPOSITORY');
export interface ProfileRepository {
  find(userId: string): Promise<Profile | null>;
  currencies(): Promise<CurrencyOption[]>;
  update(userId: string, profile: ProfileUpdate): Promise<Profile | null>;
  saveOnboarding(userId: string, answers: OnboardingAnswers): Promise<boolean>;
  saveMonthlyIncome(userId: string, minor: string | null): Promise<boolean>;
  saveDisplayCurrency(userId: string, code: string | null): Promise<boolean>;
  saveAutoSuggest(userId: string, enabled: boolean): Promise<boolean>;
}
