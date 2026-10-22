export interface Profile {
  /** Shown in greetings only. Null until the user sets it. */
  displayName: string | null;
  locale: string;
  defaultCurrencyCode: string;
  timezone: string;
  fiscalMonthStartDay: number;
  version: number;
}
/** `displayName` undefined keeps the stored value. */
export type ProfileUpdate = Omit<Profile, 'displayName'> & { displayName?: string | null };
export interface CurrencyOption { code: string; minorDigits: number; }
export const PROFILE_REPOSITORY = Symbol('PROFILE_REPOSITORY');
export interface ProfileRepository {
  find(userId: string): Promise<Profile | null>;
  currencies(): Promise<CurrencyOption[]>;
  update(userId: string, profile: ProfileUpdate): Promise<Profile | null>;
}
