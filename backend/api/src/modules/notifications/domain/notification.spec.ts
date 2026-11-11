import {
  budgetDedupeKey,
  cardDueDedupeKey,
  cardUsageDedupeKey,
  cardUsageThresholds,
  creditOutstanding,
  dailyLogDedupeKey,
  dayBefore,
  daysBetween,
  isDailyLogDue,
  isInQuietHours,
  kindToggles,
  localMinutesInTimeZone,
  nextDueDateIso,
  parseHm,
  assertKindWritable,
  NotificationError,
  defaultPreference,
} from './notification';

describe('BE-P2-E05 quiet hours', () => {
  const prefs = {
    quietHoursEnabled: true,
    quietStart: '22:00',
    quietEnd: '07:00',
  };

  it('parses HH:mm', () => {
    expect(parseHm('22:00')).toEqual({ hour: 22, minute: 0 });
    expect(() => parseHm('25:00')).toThrow(NotificationError);
  });

  it('treats overnight Asia/Ho_Chi_Minh windows as quiet', () => {
    // 2026-10-28 15:30 UTC = 22:30 ICT
    const late = new Date('2026-10-28T15:30:00.000Z');
    expect(localMinutesInTimeZone('Asia/Ho_Chi_Minh', late)).toBe(22 * 60 + 30);
    expect(isInQuietHours(prefs, 'Asia/Ho_Chi_Minh', late)).toBe(true);

    // 2026-10-28 23:30 UTC = 06:30 ICT next day
    const early = new Date('2026-10-28T23:30:00.000Z');
    expect(isInQuietHours(prefs, 'Asia/Ho_Chi_Minh', early)).toBe(true);

    // 2026-10-28 00:00 UTC = 07:00 ICT — end is exclusive
    const seven = new Date('2026-10-28T00:00:00.000Z');
    expect(isInQuietHours(prefs, 'Asia/Ho_Chi_Minh', seven)).toBe(false);

    // 2026-10-28 05:00 UTC = 12:00 ICT
    const noon = new Date('2026-10-28T05:00:00.000Z');
    expect(isInQuietHours(prefs, 'Asia/Ho_Chi_Minh', noon)).toBe(false);
  });

  it('skips quiet checks when disabled', () => {
    const noon = new Date('2026-10-28T15:30:00.000Z');
    expect(isInQuietHours({ ...prefs, quietHoursEnabled: false }, 'Asia/Ho_Chi_Minh', noon)).toBe(false);
  });
});

describe('BE-P2-E05 kinds and budget thresholds', () => {
  it('locks unavailable kinds and keeps security local', () => {
    const toggles = kindToggles({
      ...defaultPreference(),
      createdAt: new Date(),
      updatedAt: new Date(),
    });
    expect(toggles.find(t => t.kind === 'budget')).toMatchObject({ available: true, enabled: true });
    expect(toggles.find(t => t.kind === 'card')).toMatchObject({ available: true, enabled: true });
    expect(toggles.find(t => t.kind === 'goal')).toMatchObject({ available: false, enabled: false });
    expect(toggles.find(t => t.kind === 'security')).toMatchObject({
      available: true,
      managedLocally: true,
    });
  });

  it('rejects enabling a kind without a source module', () => {
    expect(() => assertKindWritable('goal', true)).toThrow(
      expect.objectContaining({ code: 'NOTIFICATION_SOURCE_UNAVAILABLE' }),
    );
    expect(() => assertKindWritable('goal', false)).not.toThrow();
    expect(() => assertKindWritable('budget', true)).not.toThrow();
    expect(() => assertKindWritable('card', true)).not.toThrow();
  });

  it('notifies only at 80+ including over', () => {
    expect(budgetDedupeKey('2026-10-01', 80)).toBe('budget|2026-10-01|80');
  });

  it('computes the calendar day before a run', () => {
    expect(dayBefore('2026-03-01')).toBe('2026-02-28');
    expect(dayBefore('2026-01-01')).toBe('2025-12-31');
  });
});

describe('BE-P2-E07 card alert helpers', () => {
  it('derives outstanding debt and usage thresholds', () => {
    expect(creditOutstanding(-500n)).toBe(500n);
    expect(creditOutstanding(100n)).toBe(0n);
    expect(cardUsageThresholds(699n, 1000n)).toEqual([]);
    expect(cardUsageThresholds(700n, 1000n)).toEqual([70]);
    expect(cardUsageThresholds(900n, 1000n)).toEqual([70, 90]);
    expect(cardUsageThresholds(500n, null)).toEqual([]);
    // BE-P5-001: levels from app config
    expect(cardUsageThresholds(650n, 1000n, { high: 60, critical: 95 })).toEqual([60]);
    expect(cardUsageThresholds(950n, 1000n, { high: 60, critical: 95 })).toEqual([60, 95]);
  });

  it('finds the next due date and days left', () => {
    expect(nextDueDateIso(15, '2026-10-12')).toBe('2026-10-15');
    expect(nextDueDateIso(10, '2026-10-12')).toBe('2026-11-10');
    expect(nextDueDateIso(null, '2026-10-12')).toBeNull();
    expect(daysBetween('2026-10-12', '2026-10-15')).toBe(3);
    expect(cardDueDedupeKey('a1', '2026-10-15')).toBe('card|due|a1|2026-10-15');
    expect(cardUsageDedupeKey('a1', '2026-10-01', 70)).toBe('card|usage|a1|2026-10-01|70');
  });
});

describe('BE-P3-006 daily log reminder helpers', () => {
  it('keys one reminder per local day', () => {
    expect(dailyLogDedupeKey('2026-11-02')).toBe('daily_log|2026-11-02');
  });

  it('is due from the reminder time in the profile timezone', () => {
    // 20:00 ICT = 13:00 UTC
    expect(isDailyLogDue('20:00', 'Asia/Ho_Chi_Minh', new Date('2026-11-02T12:59:00.000Z'))).toBe(false);
    expect(isDailyLogDue('20:00', 'Asia/Ho_Chi_Minh', new Date('2026-11-02T13:00:00.000Z'))).toBe(true);
    expect(isDailyLogDue('20:00', 'America/New_York', new Date('2026-11-02T13:00:00.000Z'))).toBe(false);
  });

  it('is available, off by default, and writable', () => {
    const toggles = kindToggles({ ...defaultPreference(), createdAt: new Date(), updatedAt: new Date() });
    expect(toggles.find(t => t.kind === 'daily_log')).toMatchObject({ available: true, enabled: false });
    expect(defaultPreference().dailyLogTime).toBe('21:00');
    expect(defaultPreference({ dailyLogTime: '19:30', quietStart: '23:00', quietEnd: '06:00' })).toMatchObject({ dailyLogTime: '19:30', quietStart: '23:00', quietEnd: '06:00' });
    expect(() => assertKindWritable('daily_log', true)).not.toThrow();
  });
});
