import { createTransport } from 'nodemailer';
import { SmtpEmailSender } from './smtp-email-sender';
import type { MailSettings } from './mail-settings';

const sendMail = jest.fn();
const verify = jest.fn();
const close = jest.fn();
jest.mock('nodemailer', () => ({
  createTransport: jest.fn(() => ({ sendMail, verify, close })),
}));
const settings: MailSettings = {
  from: 'Freeva <noreply@example.test>', host: 'smtp.example.test', port: 2465,
  secure: true, requireTLS: true, auth: { user: 'resend', pass: 'private-key' },
  idempotencyHeader: 'Resend-Idempotency-Key',
};
const message = { deliveryId: 'job-1', to: 'recipient@example.test', subject: 'Verify', text: 'secret-token' };

describe('SMTP adapter', () => {
  beforeEach(() => { jest.clearAllMocks(); sendMail.mockReset(); verify.mockReset(); });
  it('disables wire logs, requires verified TLS and forbids file/URL access', () => {
    new SmtpEmailSender(settings);
    expect(createTransport).toHaveBeenCalledWith(expect.objectContaining({
      logger: false, debug: false, disableFileAccess: true, disableUrlAccess: true,
      secure: true, requireTLS: true, tls: { minVersion: 'TLSv1.2', rejectUnauthorized: true },
    }));
  });
  it('uses the same idempotency key on retry and a new one for a new challenge', async () => {
    sendMail.mockResolvedValue({ accepted: [message.to], rejected: [] });
    const sender = new SmtpEmailSender(settings);
    await sender.send(message); await sender.send(message);
    expect(sendMail.mock.calls[0][0].headers).toEqual({ 'Resend-Idempotency-Key': 'auth/job-1' });
    expect(sendMail.mock.calls[1][0]).toEqual(sendMail.mock.calls[0][0]);
    await sender.send({ ...message, deliveryId: 'job-2' });
    expect(sendMail.mock.calls[2][0].headers).toEqual({ 'Resend-Idempotency-Key': 'auth/job-2' });
  });
  it('omits provider-specific headers with generic SMTP', async () => {
    sendMail.mockResolvedValue({ accepted: [message.to], rejected: [] });
    await new SmtpEmailSender({ ...settings, idempotencyHeader: undefined }).send(message);
    expect(sendMail.mock.calls[0][0].headers).toBeUndefined();
  });
  it.each([{ accepted: [], rejected: [message.to] }, {}, { accepted: ['different@example.test'] }])(
    'does not acknowledge an unaccepted recipient (%#)', async (result) => {
      sendMail.mockResolvedValue(result);
      await expect(new SmtpEmailSender(settings).send(message)).rejects.toThrow('Email delivery failed');
    },
  );
  it('sanitizes provider exceptions and connection checks do not send email', async () => {
    const sender = new SmtpEmailSender(settings);
    sendMail.mockRejectedValue(new Error('private-key recipient@example.test secret-token'));
    await expect(sender.send(message)).rejects.toThrow(/^Email delivery failed$/);
    sendMail.mockClear(); verify.mockResolvedValue(true);
    await sender.verify(); expect(sendMail).not.toHaveBeenCalled();
    verify.mockRejectedValue(new Error('private-key'));
    await expect(sender.verify()).rejects.toThrow(/^SMTP connection verification failed$/);
    sender.onApplicationShutdown(); expect(close).toHaveBeenCalledTimes(1);
  });
});
