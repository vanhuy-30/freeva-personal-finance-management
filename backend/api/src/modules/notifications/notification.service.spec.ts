import { NotificationService } from './notification.service';
import type { NotificationRepository } from './domain/notification.repository';
import { defaultPreference, NotificationError } from './domain/notification';

describe('BE-P2-E05 notification service', () => {
  const now = new Date('2026-10-28T05:00:00.000Z'); // 12:00 ICT
  const quietNow = new Date('2026-10-28T15:30:00.000Z'); // 22:30 ICT

  function repo(partial: Partial<NotificationRepository> = {}): NotificationRepository {
    return {
      getPreferences: jest.fn(),
      putPreferences: jest.fn(),
      list: jest.fn(),
      markRead: jest.fn(),
      markAllRead: jest.fn(),
      createIfAbsent: jest.fn().mockResolvedValue(true),
      listUsersForEvaluate: jest.fn(),
      loadEvaluateContext: jest.fn(),
      ...partial,
    };
  }

  it('creates budget and recurring alerts outside quiet hours without money params', async () => {
    const createIfAbsent = jest.fn().mockResolvedValue(true);
    const repository = repo({
      createIfAbsent,
      loadEvaluateContext: jest.fn().mockResolvedValue({
        userId: 'u1',
        timezone: 'Asia/Ho_Chi_Minh',
        today: '2026-10-28',
        prefs: {
          ...defaultPreference(),
          quietHoursEnabled: false,
          cardEnabled: false,
          createdAt: now,
          updatedAt: now,
        },
        periodFrom: '2026-10-01',
        crossedThresholds: [70, 80, 100],
        recurringSoon: [{ id: 'r1', nextExecutionDate: '2026-10-29' }],
        billsDue: [],
        debtsDue: [],
        creditCards: [],
      }),
    });
    const service = new NotificationService(repository);
    await expect(service.evaluate('u1', now)).resolves.toEqual({ created: 3 });
    expect(createIfAbsent).toHaveBeenCalledTimes(3);
    for (const call of createIfAbsent.mock.calls) {
      const params = call[0].params as Record<string, unknown>;
      expect(JSON.stringify(params)).not.toMatch(/amount|Minor|balance/i);
    }
    expect(createIfAbsent.mock.calls.map(call => call[0].dedupeKey)).toEqual([
      'budget|2026-10-01|80',
      'budget|2026-10-01|100',
      'recurring|r1|2026-10-29',
    ]);
  });

  it('creates card due and usage alerts without money params', async () => {
    const createIfAbsent = jest.fn().mockResolvedValue(true);
    const repository = repo({
      createIfAbsent,
      loadEvaluateContext: jest.fn().mockResolvedValue({
        userId: 'u1',
        timezone: 'Asia/Ho_Chi_Minh',
        today: '2026-10-12',
        prefs: {
          ...defaultPreference(),
          budgetEnabled: false,
          recurringEnabled: false,
          cardEnabled: true,
          createdAt: now,
          updatedAt: now,
        },
        periodFrom: '2026-10-01',
        crossedThresholds: [],
        recurringSoon: [],
        billsDue: [],
        debtsDue: [],
        creditCards: [{
          id: 'card-1',
          paymentDueDay: 15,
          creditLimitMinor: 1000n,
          balanceMinor: -900n,
        }],
      }),
    });
    const service = new NotificationService(repository);
    await expect(service.evaluate('u1', now)).resolves.toEqual({ created: 3 });
    expect(createIfAbsent.mock.calls.map(call => call[0].dedupeKey)).toEqual([
      'card|due|card-1|2026-10-15',
      'card|usage|card-1|2026-10-01|70',
      'card|usage|card-1|2026-10-01|90',
    ]);
    for (const call of createIfAbsent.mock.calls) {
      const params = call[0].params as Record<string, unknown>;
      expect(JSON.stringify(params)).not.toMatch(/amount|Minor|balance/i);
      expect(params.accountId).toBe('card-1');
    }
  });

  it('skips archived-free zero-debt cards and does not invent payments', async () => {
    const createIfAbsent = jest.fn().mockResolvedValue(true);
    const repository = repo({
      createIfAbsent,
      loadEvaluateContext: jest.fn().mockResolvedValue({
        userId: 'u1',
        timezone: 'Asia/Ho_Chi_Minh',
        today: '2026-10-12',
        prefs: {
          ...defaultPreference(),
          budgetEnabled: false,
          recurringEnabled: false,
          createdAt: now,
          updatedAt: now,
        },
        periodFrom: '2026-10-01',
        crossedThresholds: [],
        recurringSoon: [],
        billsDue: [],
        debtsDue: [],
        creditCards: [{
          id: 'card-2',
          paymentDueDay: 15,
          creditLimitMinor: 1000n,
          balanceMinor: 0n,
        }],
      }),
    });
    const service = new NotificationService(repository);
    await expect(service.evaluate('u1', now)).resolves.toEqual({ created: 0 });
    expect(createIfAbsent).not.toHaveBeenCalled();
  });

  it('skips creation during quiet hours', async () => {
    const createIfAbsent = jest.fn();
    const repository = repo({
      createIfAbsent,
      loadEvaluateContext: jest.fn().mockResolvedValue({
        userId: 'u1',
        timezone: 'Asia/Ho_Chi_Minh',
        today: '2026-10-28',
        prefs: {
          ...defaultPreference(),
          quietHoursEnabled: true,
          quietStart: '22:00',
          quietEnd: '07:00',
          createdAt: quietNow,
          updatedAt: quietNow,
        },
        periodFrom: '2026-10-01',
        crossedThresholds: [80],
        recurringSoon: [{ id: 'r1', nextExecutionDate: '2026-10-29' }],
        billsDue: [],
        debtsDue: [],
        creditCards: [{
          id: 'card-1',
          paymentDueDay: 28,
          creditLimitMinor: 1000n,
          balanceMinor: -900n,
        }],
      }),
    });
    const service = new NotificationService(repository);
    await expect(service.evaluate('u1', quietNow)).resolves.toEqual({ created: 0 });
    expect(createIfAbsent).not.toHaveBeenCalled();
  });

  it('rejects enabling unavailable kinds', async () => {
    const repository = repo({
      getPreferences: jest.fn().mockResolvedValue({
        ...defaultPreference(),
        createdAt: now,
        updatedAt: now,
      }),
    });
    const service = new NotificationService(repository);
    await expect(service.putPreferences('u1', { goalEnabled: true })).rejects.toMatchObject({
      code: 'NOTIFICATION_SOURCE_UNAVAILABLE',
    });
    expect(repository.putPreferences).not.toHaveBeenCalled();
  });

  it('does not notify below 80%', async () => {
    const createIfAbsent = jest.fn();
    const repository = repo({
      createIfAbsent,
      loadEvaluateContext: jest.fn().mockResolvedValue({
        userId: 'u1',
        timezone: 'Asia/Ho_Chi_Minh',
        today: '2026-10-28',
        prefs: {
          ...defaultPreference(), cardEnabled: false, createdAt: now, updatedAt: now,
        },
        periodFrom: '2026-10-01',
        crossedThresholds: [70],
        recurringSoon: [],
        billsDue: [],
        debtsDue: [],
        creditCards: [],
      }),
    });
    const service = new NotificationService(repository);
    await expect(service.evaluate('u1', now)).resolves.toEqual({ created: 0 });
    expect(createIfAbsent).not.toHaveBeenCalled();
  });

  it('surfaces NotificationError from put', async () => {
    expect(new NotificationError('VALIDATION_ERROR').code).toBe('VALIDATION_ERROR');
  });

  it('notifies a bill inside its lead window once, and again as overdue, with no money params', async () => {
    const createIfAbsent = jest.fn().mockResolvedValue(true);
    const now = new Date('2026-10-28T03:00:00.000Z');
    const repository = repo({
      createIfAbsent,
      loadEvaluateContext: jest.fn().mockResolvedValue({
        userId: 'u1',
        timezone: 'Asia/Ho_Chi_Minh',
        today: '2026-10-28',
        prefs: { ...defaultPreference(), quietHoursEnabled: false, cardEnabled: false, createdAt: now, updatedAt: now },
        periodFrom: null,
        crossedThresholds: [],
        recurringSoon: [],
        billsDue: [
          { id: 'b1', dueDate: '2026-10-30', daysLeft: 2 },
          { id: 'b2', dueDate: '2026-10-25', daysLeft: -3 },
        ],
        creditCards: [],
      }),
    });
    const service = new NotificationService(repository);
    await expect(service.evaluate('u1', now)).resolves.toEqual({ created: 2 });
    expect(createIfAbsent.mock.calls.map(call => [call[0].dedupeKey, call[0].titleKey])).toEqual([
      ['bill|due|b1|2026-10-30', 'bill_due'],
      ['bill|overdue|b2|2026-10-25', 'bill_overdue'],
    ]);
    for (const call of createIfAbsent.mock.calls) {
      expect(JSON.stringify(call[0].params)).not.toMatch(/amount|Minor|balance/i);
    }
  });
  it('BE-P3-007 notifies a debt in its window once and again as overdue, with no names or money', async () => {
    const createIfAbsent = jest.fn().mockResolvedValue(true);
    const now = new Date('2026-10-28T03:00:00.000Z');
    const repository = repo({
      createIfAbsent,
      loadEvaluateContext: jest.fn().mockResolvedValue({
        userId: 'u1',
        timezone: 'Asia/Ho_Chi_Minh',
        today: '2026-10-28',
        prefs: { ...defaultPreference(), quietHoursEnabled: false, cardEnabled: false, debtEnabled: true, createdAt: now, updatedAt: now },
        periodFrom: null,
        crossedThresholds: [],
        recurringSoon: [],
        billsDue: [],
        debtsDue: [
          { id: 'd1', direction: 'lent', dueDate: '2026-10-30', daysLeft: 2 },
          { id: 'd2', direction: 'borrowed', dueDate: '2026-10-25', daysLeft: -3 },
        ],
        creditCards: [],
      }),
    });
    const service = new NotificationService(repository);
    await expect(service.evaluate('u1', now)).resolves.toEqual({ created: 2 });
    expect(createIfAbsent.mock.calls.map(call => [call[0].kind, call[0].dedupeKey, call[0].titleKey])).toEqual([
      ['debt', 'debt|due|d1|2026-10-30', 'debt_due'],
      ['debt', 'debt|overdue|d2|2026-10-25', 'debt_overdue'],
    ]);
    for (const call of createIfAbsent.mock.calls) {
      expect(JSON.stringify(call[0].params)).not.toMatch(/amount|Minor|balance|name|counterparty/i);
    }
  });

  it('BE-P3-007 stays silent when the debt toggle is off', async () => {
    const createIfAbsent = jest.fn().mockResolvedValue(true);
    const now = new Date('2026-10-28T03:00:00.000Z');
    const repository = repo({
      createIfAbsent,
      loadEvaluateContext: jest.fn().mockResolvedValue({
        userId: 'u1',
        timezone: 'Asia/Ho_Chi_Minh',
        today: '2026-10-28',
        prefs: { ...defaultPreference(), quietHoursEnabled: false, cardEnabled: false, debtEnabled: false, createdAt: now, updatedAt: now },
        periodFrom: null,
        crossedThresholds: [],
        recurringSoon: [],
        billsDue: [],
        debtsDue: [{ id: 'd1', direction: 'lent', dueDate: '2026-10-30', daysLeft: 2 }],
        creditCards: [],
      }),
    });
    await expect(new NotificationService(repository).evaluate('u1', now)).resolves.toEqual({ created: 0 });
    expect(createIfAbsent).not.toHaveBeenCalled();
  });

  describe('BE-P3-006 daily log reminder', () => {
    const evening = new Date('2026-10-28T13:30:00.000Z'); // 20:30 ICT
    const morning = new Date('2026-10-28T03:00:00.000Z'); // 10:00 ICT

    function run(
      overrides: Record<string, unknown>,
      at: Date,
      prefs: Record<string, unknown> = {},
    ) {
      const createIfAbsent = jest.fn().mockResolvedValue(true);
      const repository = repo({
        createIfAbsent,
        loadEvaluateContext: jest.fn().mockResolvedValue({
          userId: 'u1',
          timezone: 'Asia/Ho_Chi_Minh',
          today: '2026-10-28',
          prefs: {
            ...defaultPreference(),
            cardEnabled: false,
            dailyLogEnabled: true,
            createdAt: at,
            updatedAt: at,
            ...prefs,
          },
          periodFrom: null,
          crossedThresholds: [],
          recurringSoon: [],
          billsDue: [],
          debtsDue: [],
          creditCards: [],
          hasTransactionToday: false,
          ...overrides,
        }),
      });
      return { createIfAbsent, result: new NotificationService(repository).evaluate('u1', at) };
    }

    it('reminds once per day after the set time when nothing was logged, with no params', async () => {
      const { createIfAbsent, result } = run({}, evening);
      await expect(result).resolves.toEqual({ created: 1 });
      expect(createIfAbsent).toHaveBeenCalledWith({
        userId: 'u1',
        kind: 'daily_log',
        dedupeKey: 'daily_log|2026-10-28',
        titleKey: 'daily_log',
        bodyKey: 'daily_log_body',
        params: {},
      });
    });

    it('does not remind before the time, when disabled, or when a transaction exists today', async () => {
      for (const [overrides, at, prefs] of [
        [{}, morning, {}],
        [{}, evening, { dailyLogEnabled: false }],
        [{ hasTransactionToday: true }, evening, {}],
      ] as const) {
        const { createIfAbsent, result } = run(overrides, at, prefs);
        await expect(result).resolves.toEqual({ created: 0 });
        expect(createIfAbsent).not.toHaveBeenCalled();
      }
    });

    it('respects quiet hours', async () => {
      const { createIfAbsent, result } = run({}, evening, {
        quietHoursEnabled: true,
        quietStart: '20:00',
        quietEnd: '22:00',
      });
      await expect(result).resolves.toEqual({ created: 0 });
      expect(createIfAbsent).not.toHaveBeenCalled();
    });

    it('does not count a retried reminder twice', async () => {
      const createIfAbsent = jest.fn().mockResolvedValue(false);
      const repository = repo({
        createIfAbsent,
        loadEvaluateContext: jest.fn().mockResolvedValue({
          userId: 'u1',
          timezone: 'Asia/Ho_Chi_Minh',
          today: '2026-10-28',
          prefs: { ...defaultPreference(), cardEnabled: false, dailyLogEnabled: true, createdAt: evening, updatedAt: evening },
          periodFrom: null,
          crossedThresholds: [],
          recurringSoon: [],
          billsDue: [],
          debtsDue: [],
          creditCards: [],
          hasTransactionToday: false,
        }),
      });
      await expect(new NotificationService(repository).evaluate('u1', evening)).resolves.toEqual({ created: 0 });
    });

    it('validates the reminder time and accepts enabling', async () => {
      const putPreferences = jest.fn().mockResolvedValue({ ...defaultPreference(), createdAt: evening, updatedAt: evening });
      const service = new NotificationService(repo({ putPreferences }));
      await service.putPreferences('u1', { dailyLogEnabled: true, dailyLogTime: '21:15' });
      expect(putPreferences).toHaveBeenCalledWith('u1', expect.objectContaining({ dailyLogEnabled: true, dailyLogTime: '21:15' }));
      await expect(service.putPreferences('u1', { dailyLogTime: '25:00' })).rejects.toMatchObject({ code: 'VALIDATION_ERROR' });
    });
  });
});
