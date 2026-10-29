import type {
  NotificationKind,
  NotificationPreferenceRecord,
  NotificationRecord,
} from './notification';

export const NOTIFICATION_REPOSITORY = Symbol('NOTIFICATION_REPOSITORY');

export type PreferencePatch = {
  budgetEnabled?: boolean;
  goalEnabled?: boolean;
  debtEnabled?: boolean;
  cardEnabled?: boolean;
  recurringEnabled?: boolean;
  monthReviewEnabled?: boolean;
  insightEnabled?: boolean;
  quietHoursEnabled?: boolean;
  quietStart?: string;
  quietEnd?: string;
  version?: number;
};

export type CreateNotificationInput = {
  userId: string;
  kind: NotificationKind;
  dedupeKey: string;
  titleKey: string;
  bodyKey: string;
  params: Record<string, string | number>;
};

export type RecurringSoonRow = {
  id: string;
  nextExecutionDate: string;
};

/** Active credit wallet for card alerts (BE-P2-E07). Balance includes initial + undeleted legs. */
export type CreditCardRow = {
  id: string;
  paymentDueDay: number | null;
  creditLimitMinor: bigint | null;
  balanceMinor: bigint;
};

export type EvaluateUserContext = {
  userId: string;
  timezone: string;
  /** Local calendar day in the profile timezone (YYYY-MM-DD). */
  today: string;
  prefs: NotificationPreferenceRecord;
  /** Fiscal month start (YYYY-MM-DD) for budget and card usage dedupe. */
  periodFrom: string | null;
  crossedThresholds: number[];
  recurringSoon: RecurringSoonRow[];
  creditCards: CreditCardRow[];
};

export interface NotificationRepository {
  getPreferences(userId: string): Promise<NotificationPreferenceRecord>;
  putPreferences(userId: string, patch: PreferencePatch): Promise<NotificationPreferenceRecord>;
  list(userId: string): Promise<NotificationRecord[]>;
  markRead(userId: string, id: string): Promise<NotificationRecord>;
  markAllRead(userId: string): Promise<number>;
  /** Insert if dedupeKey is new; returns whether a row was created. */
  createIfAbsent(input: CreateNotificationInput): Promise<boolean>;
  /** Users with prefs or defaults that may need evaluation. */
  listUsersForEvaluate(): Promise<Array<{ userId: string; timezone: string }>>;
  loadEvaluateContext(userId: string, now: Date): Promise<EvaluateUserContext>;
}
