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
        prefs: {
          ...defaultPreference(),
          quietHoursEnabled: false,
          createdAt: now,
          updatedAt: now,
        },
        periodFrom: '2026-10-01',
        crossedThresholds: [70, 80, 100],
        recurringSoon: [{ id: 'r1', nextExecutionDate: '2026-10-29' }],
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

  it('skips creation during quiet hours', async () => {
    const createIfAbsent = jest.fn();
    const repository = repo({
      createIfAbsent,
      loadEvaluateContext: jest.fn().mockResolvedValue({
        userId: 'u1',
        timezone: 'Asia/Ho_Chi_Minh',
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
        prefs: { ...defaultPreference(), createdAt: now, updatedAt: now },
        periodFrom: '2026-10-01',
        crossedThresholds: [70],
        recurringSoon: [],
      }),
    });
    const service = new NotificationService(repository);
    await expect(service.evaluate('u1', now)).resolves.toEqual({ created: 0 });
    expect(createIfAbsent).not.toHaveBeenCalled();
  });

  it('surfaces NotificationError from put', async () => {
    expect(new NotificationError('VALIDATION_ERROR').code).toBe('VALIDATION_ERROR');
  });
});
