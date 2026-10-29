/** BE-P2-E05 — notification kinds, quiet hours, and preference rules. */

export const NOTIFICATION_KINDS = [
  'budget',
  'goal',
  'debt',
  'card',
  'recurring',
  'month_review',
  'insight',
  'security',
] as const;

export type NotificationKind = (typeof NOTIFICATION_KINDS)[number];

/** Kinds whose source module exists today. Others stay locked off. */
export const AVAILABLE_KINDS = new Set<NotificationKind>(['budget', 'recurring', 'card', 'security']);

export const DEFAULT_QUIET_START = '22:00';
export const DEFAULT_QUIET_END = '07:00';

/** Budget alerts fire at 80% and at/over the limit (100), not at 70. */
export const BUDGET_NOTIFY_MIN_THRESHOLD = 80;

/** Card due alerts fire when payment is 0–3 calendar days away (profile timezone). */
export const CARD_DUE_WINDOW_DAYS = 3;

/** High outstanding vs limit; near-limit is a separate inbox row. */
export const CARD_HIGH_USAGE_THRESHOLD = 70;
export const CARD_NEAR_LIMIT_THRESHOLD = 90;

export class NotificationError extends Error {
  constructor(
    readonly code:
      | 'VALIDATION_ERROR'
      | 'NOTIFICATION_NOT_FOUND'
      | 'NOTIFICATION_SOURCE_UNAVAILABLE'
      | 'NOTIFICATION_CONFLICT',
  ) {
    super(code);
    this.name = 'NotificationError';
  }
}

export type QuietHours = {
  quietHoursEnabled: boolean;
  quietStart: string;
  quietEnd: string;
};

export type NotificationPreferenceRecord = QuietHours & {
  budgetEnabled: boolean;
  goalEnabled: boolean;
  debtEnabled: boolean;
  cardEnabled: boolean;
  recurringEnabled: boolean;
  monthReviewEnabled: boolean;
  insightEnabled: boolean;
  version: number;
  createdAt: Date;
  updatedAt: Date;
};

export type KindToggle = {
  kind: NotificationKind;
  enabled: boolean;
  available: boolean;
  /** security is toggled on the device only. */
  managedLocally: boolean;
};

export type NotificationRecord = {
  id: string;
  kind: NotificationKind;
  dedupeKey: string;
  titleKey: string;
  bodyKey: string;
  params: Record<string, string | number>;
  createdAt: Date;
  readAt: Date | null;
};

const HM = /^([01]\d|2[0-3]):([0-5]\d)$/;

export function parseHm(value: string): { hour: number; minute: number } {
  const match = HM.exec(value);
  if (!match) throw new NotificationError('VALIDATION_ERROR');
  return { hour: Number(match[1]), minute: Number(match[2]) };
}

export function validateQuietWindow(start: string, end: string): void {
  parseHm(start);
  parseHm(end);
  if (start === end) throw new NotificationError('VALIDATION_ERROR');
}

export function minutesOfDay(value: string): number {
  const { hour, minute } = parseHm(value);
  return hour * 60 + minute;
}

/** Local clock minutes in `timeZone` (0–1439). */
export function localMinutesInTimeZone(timeZone: string, now: Date): number {
  const parts = new Intl.DateTimeFormat('en-US', {
    timeZone,
    hour: '2-digit',
    minute: '2-digit',
    hourCycle: 'h23',
  }).formatToParts(now);
  const hour = Number(parts.find(part => part.type === 'hour')?.value);
  const minute = Number(parts.find(part => part.type === 'minute')?.value);
  if (!Number.isInteger(hour) || !Number.isInteger(minute)) {
    throw new NotificationError('VALIDATION_ERROR');
  }
  return hour * 60 + minute;
}

/**
 * Quiet window in the profile timezone. Overnight (22:00–07:00) wraps midnight.
 * End is exclusive so 07:00 is outside a 22:00–07:00 window.
 */
export function isInQuietHours(prefs: QuietHours, timeZone: string, now: Date): boolean {
  if (!prefs.quietHoursEnabled) return false;
  validateQuietWindow(prefs.quietStart, prefs.quietEnd);
  const nowM = localMinutesInTimeZone(timeZone, now);
  const start = minutesOfDay(prefs.quietStart);
  const end = minutesOfDay(prefs.quietEnd);
  if (start < end) return nowM >= start && nowM < end;
  return nowM >= start || nowM < end;
}

export function defaultPreference(): Omit<NotificationPreferenceRecord, 'createdAt' | 'updatedAt' | 'version'> & {
  version: number;
} {
  return {
    budgetEnabled: true,
    goalEnabled: false,
    debtEnabled: false,
    cardEnabled: true,
    recurringEnabled: true,
    monthReviewEnabled: false,
    insightEnabled: false,
    quietHoursEnabled: false,
    quietStart: DEFAULT_QUIET_START,
    quietEnd: DEFAULT_QUIET_END,
    version: 1,
  };
}

export function kindToggles(prefs: NotificationPreferenceRecord): KindToggle[] {
  const enabled = (kind: NotificationKind): boolean => {
    switch (kind) {
      case 'budget':
        return prefs.budgetEnabled;
      case 'goal':
        return prefs.goalEnabled;
      case 'debt':
        return prefs.debtEnabled;
      case 'card':
        return prefs.cardEnabled;
      case 'recurring':
        return prefs.recurringEnabled;
      case 'month_review':
        return prefs.monthReviewEnabled;
      case 'insight':
        return prefs.insightEnabled;
      case 'security':
        return true;
    }
  };
  return NOTIFICATION_KINDS.map(kind => {
    const available = AVAILABLE_KINDS.has(kind);
    return {
      kind,
      available,
      managedLocally: kind === 'security',
      enabled: available ? enabled(kind) && (kind !== 'security' || true) : false,
    };
  });
}

export function assertKindWritable(kind: NotificationKind, enabled: boolean): void {
  if (kind === 'security') throw new NotificationError('VALIDATION_ERROR');
  if (!AVAILABLE_KINDS.has(kind) && enabled) {
    throw new NotificationError('NOTIFICATION_SOURCE_UNAVAILABLE');
  }
}

/** Thresholds to alert on: crossed values at or above 80 (includes 100 / over). */
export function budgetNotifyThresholds(crossed: number[]): number[] {
  return crossed.filter(threshold => threshold >= BUDGET_NOTIFY_MIN_THRESHOLD);
}

export function budgetDedupeKey(periodFrom: string, threshold: number): string {
  return `budget|${periodFrom}|${threshold}`;
}

export function recurringDedupeKey(ruleId: string, executionDate: string): string {
  return `recurring|${ruleId}|${executionDate}`;
}

export function cardDueDedupeKey(accountId: string, dueDate: string): string {
  return `card|due|${accountId}|${dueDate}`;
}

export function cardUsageDedupeKey(accountId: string, periodFrom: string, threshold: number): string {
  return `card|usage|${accountId}|${periodFrom}|${threshold}`;
}

/** Outstanding debt from a credit balance (negative balance = debt). */
export function creditOutstanding(balanceMinor: bigint): bigint {
  return balanceMinor < 0n ? -balanceMinor : 0n;
}

/**
 * Usage percent of the limit (truncated). Empty when there is no positive limit.
 * Returns 70 and/or 90 when crossed — same style as budgetNotifyThresholds.
 */
export function cardUsageThresholds(used: bigint, limit: bigint | null): number[] {
  if (limit === null || limit <= 0n || used <= 0n) return [];
  const percent = Number((used * 100n) / limit);
  const crossed: number[] = [];
  if (percent >= CARD_HIGH_USAGE_THRESHOLD) crossed.push(CARD_HIGH_USAGE_THRESHOLD);
  if (percent >= CARD_NEAR_LIMIT_THRESHOLD) crossed.push(CARD_NEAR_LIMIT_THRESHOLD);
  return crossed;
}

/** Next occurrence of dueDay on or after todayIso (YYYY-MM-DD); clamps to month end. */
export function nextDueDateIso(dueDay: number | null, todayIso: string): string | null {
  if (dueDay === null || dueDay < 1) return null;
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(todayIso);
  if (!match) throw new NotificationError('VALIDATION_ERROR');
  let year = Number(match[1]);
  let month = Number(match[2]);
  const on = (y: number, m: number): string => {
    const last = new Date(Date.UTC(y, m, 0)).getUTCDate();
    const day = dueDay > last ? last : dueDay;
    return `${y}-${String(m).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
  };
  const thisMonth = on(year, month);
  if (thisMonth >= todayIso) return thisMonth;
  month += 1;
  if (month > 12) {
    month = 1;
    year += 1;
  }
  return on(year, month);
}

/** Whole calendar days from fromIso to toIso (UTC date math). */
export function daysBetween(fromIso: string, toIso: string): number {
  const from = Date.parse(`${fromIso}T00:00:00.000Z`);
  const to = Date.parse(`${toIso}T00:00:00.000Z`);
  if (!Number.isFinite(from) || !Number.isFinite(to)) throw new NotificationError('VALIDATION_ERROR');
  return Math.round((to - from) / 86_400_000);
}

/** YYYY-MM-DD minus one calendar day (UTC date math). */
export function dayBefore(isoDay: string): string {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(isoDay);
  if (!match) throw new NotificationError('VALIDATION_ERROR');
  const utc = Date.UTC(Number(match[1]), Number(match[2]) - 1, Number(match[3]));
  const prev = new Date(utc - 86_400_000);
  const y = prev.getUTCFullYear();
  const m = String(prev.getUTCMonth() + 1).padStart(2, '0');
  const d = String(prev.getUTCDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}
