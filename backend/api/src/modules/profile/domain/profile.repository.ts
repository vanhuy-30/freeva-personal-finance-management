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
  trackingHabit: string | null;
  reviewCadence: string | null;
  /** Minor units as a string; null until typed. Not converted when the profile currency changes. */
  onboardingBudgetMinor: string | null;
}
/** `displayName` undefined keeps the stored value. */
export type ProfileUpdate = Omit<Profile, 'displayName' | 'goals' | 'trackingHabit' | 'reviewCadence' | 'onboardingBudgetMinor'> & { displayName?: string | null };
/** Only the fields present are stored; the rest keep their value. */
export interface OnboardingAnswers {
  goals?: string[];
  trackingHabit?: string;
  reviewCadence?: string;
  budgetMinor?: string;
}
export interface CurrencyOption { code: string; minorDigits: number; }
export const PROFILE_REPOSITORY = Symbol('PROFILE_REPOSITORY');
export interface ProfileRepository {
  find(userId: string): Promise<Profile | null>;
  currencies(): Promise<CurrencyOption[]>;
  update(userId: string, profile: ProfileUpdate): Promise<Profile | null>;
  saveOnboarding(userId: string, answers: OnboardingAnswers): Promise<boolean>;
}
