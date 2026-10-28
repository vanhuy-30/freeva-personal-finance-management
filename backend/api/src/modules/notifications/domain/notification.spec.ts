import {
  budgetDedupeKey,
  budgetNotifyThresholds,
  dayBefore,
  isInQuietHours,
  kindToggles,
  localMinutesInTimeZone,
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
  });

  it('notifies only at 80+ including over', () => {
    expect(budgetNotifyThresholds([70, 80, 90, 100])).toEqual([80, 90, 100]);
    expect(budgetNotifyThresholds([70])).toEqual([]);
    expect(budgetDedupeKey('2026-10-01', 80)).toBe('budget|2026-10-01|80');
  });

  it('computes the calendar day before a run', () => {
    expect(dayBefore('2026-03-01')).toBe('2026-02-28');
    expect(dayBefore('2026-01-01')).toBe('2025-12-31');
  });
});
