import { PushService } from './push.service';
import type { PushSender } from './domain/push-sender';
import type { PendingPush, PushTokenRepository } from './domain/push-token.repository';

describe('BE-P2-015 push service', () => {
  const noon = new Date('2026-10-28T05:00:00.000Z'); // 12:00 ICT
  const quiet = new Date('2026-10-28T15:30:00.000Z'); // 22:30 ICT

  const row = (over: Partial<PendingPush> = {}): PendingPush => ({
    id: 'n1',
    userId: 'u1',
    kind: 'budget',
    titleKey: 'budget_threshold',
    bodyKey: 'budget_threshold_body',
    params: { threshold: 80, periodFrom: '2026-10-01' },
    locale: 'vi',
    timezone: 'Asia/Ho_Chi_Minh',
    quietHoursEnabled: false,
    quietStart: '22:00',
    quietEnd: '07:00',
    ...over,
  });

  function setup(pending: PendingPush[], send: PushSender['send'], enabled = true) {
    const repo: jest.Mocked<PushTokenRepository> = {
      upsert: jest.fn(),
      removeBySession: jest.fn(),
      removeByToken: jest.fn(),
      tokensForUser: jest.fn().mockResolvedValue([{ token: 'tok-1', platform: 'android' }]),
      pending: jest.fn().mockResolvedValue(pending),
      claim: jest.fn().mockResolvedValue(true),
      release: jest.fn(),
    };
    const sender: PushSender = { enabled, send };
    return { repo, service: new PushService(repo, sender) };
  }

  it('sends one push with vi text and only the inbox id and kind as data', async () => {
    const send = jest.fn().mockResolvedValue('sent');
    const { service, repo } = setup([row()], send);
    await service.drain('u1', noon);
    expect(send).toHaveBeenCalledTimes(1);
    const message = send.mock.calls[0][0];
    expect(message.title).toBe('Ngân sách đã chạm 80%');
    expect(message.data).toEqual({ notificationId: 'n1', kind: 'budget' });
    expect(JSON.stringify(message)).not.toMatch(/accountId|balance|email|periodFrom/i);
    expect(repo.release).not.toHaveBeenCalled();
  });

  it('uses English for en profiles', async () => {
    const send = jest.fn().mockResolvedValue('sent');
    const { service } = setup([row({ locale: 'en' })], send);
    await service.drain(null, noon);
    expect(send.mock.calls[0][0].title).toBe('Budget reached 80%');
  });

  it('leaves the row unclaimed during quiet hours so it goes out after', async () => {
    const send = jest.fn().mockResolvedValue('sent');
    const { service, repo } = setup([row({ quietHoursEnabled: true })], send);
    await service.drain('u1', quiet);
    expect(repo.claim).not.toHaveBeenCalled();
    expect(send).not.toHaveBeenCalled();
    await service.drain('u1', new Date('2026-10-28T00:30:00.000Z')); // 07:30 ICT
    expect(send).toHaveBeenCalledTimes(1);
  });

  it('skips rows another worker already claimed', async () => {
    const send = jest.fn().mockResolvedValue('sent');
    const { service, repo } = setup([row()], send);
    repo.claim.mockResolvedValue(false);
    await service.drain('u1', noon);
    expect(send).not.toHaveBeenCalled();
  });

  it('removes invalid tokens and keeps the row claimed', async () => {
    const send = jest.fn().mockResolvedValue('invalid_token');
    const { service, repo } = setup([row()], send);
    await service.drain('u1', noon);
    expect(repo.removeByToken).toHaveBeenCalledWith('tok-1');
    expect(repo.release).not.toHaveBeenCalled();
  });

  it('releases the row after a transient failure so the next tick retries', async () => {
    const send = jest.fn().mockResolvedValue('transient');
    const { service, repo } = setup([row()], send);
    await service.drain('u1', noon);
    expect(repo.release).toHaveBeenCalledWith('n1');
  });

  it('does nothing when FCM is not configured', async () => {
    const send = jest.fn();
    const { service, repo } = setup([row()], send, false);
    await service.drain('u1', noon);
    expect(repo.pending).not.toHaveBeenCalled();
    expect(send).not.toHaveBeenCalled();
  });
});
