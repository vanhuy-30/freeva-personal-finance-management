import { Logger } from '@nestjs/common';
import { AuthMailWorker } from './auth-mail.worker';
import { AuthCrypto } from './auth-crypto';
import type { AuthRepository } from '../domain/auth.repository';
import type { EmailSender } from '../../mail/domain/email-sender';

const job = { id: 'job-1', email: 'recipient@example.test', purpose: 'verify_email', encryptedToken: 'ciphertext' };

describe('provider-independent auth mail worker', () => {
  const cleanup = jest.fn();
  const claimMail = jest.fn();
  const completeMail = jest.fn();
  const send = jest.fn();
  let worker: AuthMailWorker;
  beforeEach(() => {
    jest.resetAllMocks();
    cleanup.mockResolvedValue(undefined);
    completeMail.mockResolvedValue(undefined);
    send.mockResolvedValue(undefined);
    claimMail.mockResolvedValueOnce(job).mockResolvedValue(null);
    worker = new AuthMailWorker(
      { cleanup, claimMail, completeMail } as unknown as AuthRepository,
      { decrypt: () => 'secret-token' } as unknown as AuthCrypto,
      { send } as EmailSender,
    );
  });
  afterEach(() => jest.restoreAllMocks());

  it('sends provider-neutral content and acknowledges only after acceptance', async () => {
    await worker.flush();
    expect(send).toHaveBeenCalledWith(expect.objectContaining({
      deliveryId: job.id, to: job.email, subject: 'Freeva — Xác thực email',
      text: expect.stringContaining('secret-token'),
    }));
    expect(completeMail).toHaveBeenCalledWith(job.id);
    expect(send.mock.invocationCallOrder[0]).toBeLessThan(completeMail.mock.invocationCallOrder[0]);
  });
  it('keeps failed delivery for retry and never logs provider errors or recipient', async () => {
    const warn = jest.spyOn(Logger.prototype, 'warn').mockImplementation();
    send.mockRejectedValue(new Error('recipient@example.test secret-token private-key'));
    await worker.flush();
    expect(completeMail).not.toHaveBeenCalled();
    expect(warn).toHaveBeenCalledWith('Auth email delivery failed; retry scheduled');
    expect(JSON.stringify(warn.mock.calls)).not.toMatch(/recipient|secret-token|private-key/);
  });
  it('shares an in-flight flush and waits for it during shutdown', async () => {
    let finish!: () => void;
    send.mockImplementation(() => new Promise<void>((resolve) => { finish = resolve; }));
    const first = worker.flush();
    expect(worker.flush()).toBe(first);
    await new Promise((resolve) => setImmediate(resolve));
    let stopped = false;
    const shutdown = worker.onModuleDestroy().then(() => { stopped = true; });
    await Promise.resolve(); expect(stopped).toBe(false);
    finish(); await shutdown;
    expect(completeMail).toHaveBeenCalledTimes(1);
  });
});
