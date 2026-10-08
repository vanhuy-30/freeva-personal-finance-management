export interface Profile {
  locale: string;
  defaultCurrencyCode: string;
  timezone: string;
  fiscalMonthStartDay: number;
  version: number;
}
export interface CurrencyOption { code: string; minorDigits: number; }
export const PROFILE_REPOSITORY = Symbol('PROFILE_REPOSITORY');
export interface ProfileRepository {
  find(userId: string): Promise<Profile | null>;
  currencies(): Promise<CurrencyOption[]>;
  update(userId: string, profile: Profile): Promise<Profile | null>;
}
