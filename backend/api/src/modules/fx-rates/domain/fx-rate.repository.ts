export interface FxRate { fromCode: string; toCode: string; rate: string; quotedAt: string }
export interface FxCurrency { code: string; minorDigits: number }
export const FX_RATE_REPOSITORY = Symbol('FX_RATE_REPOSITORY');
export interface FxRateRepository {
  list(userId: string): Promise<FxRate[]>;
  currencies(): Promise<FxCurrency[]>;
  /** Default currency of the profile, the target of detail screens. */
  defaultCurrency(userId: string): Promise<string | null>;
  /** One row per direction; replaces the previous rate and time. */
  upsert(userId: string, rate: FxRate): Promise<FxRate>;
  remove(userId: string, fromCode: string, toCode: string): Promise<boolean>;
}
