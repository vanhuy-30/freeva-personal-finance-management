import type { OnApplicationShutdown } from '@nestjs/common';
import { createTransport, type Transporter } from 'nodemailer';
import type SMTPTransport from 'nodemailer/lib/smtp-transport';
import type { EmailMessage, EmailSender } from '../domain/email-sender';
import type { MailSettings } from './mail-settings';

export class SmtpEmailSender implements EmailSender, OnApplicationShutdown {
  private readonly transport: Transporter<SMTPTransport.SentMessageInfo>;

  constructor(private readonly settings: MailSettings) {
    this.transport = createTransport({
      host: settings.host,
      port: settings.port,
      secure: settings.secure,
      requireTLS: settings.requireTLS,
      auth: settings.auth,
      tls: { minVersion: 'TLSv1.2', rejectUnauthorized: true },
      connectionTimeout: 10_000,
      greetingTimeout: 10_000,
      socketTimeout: 15_000,
      logger: false,
      debug: false,
      disableFileAccess: true,
      disableUrlAccess: true,
    });
  }

  async send(message: EmailMessage): Promise<void> {
    try {
      const result = await this.transport.sendMail({
        from: this.settings.from,
        to: message.to,
        subject: message.subject,
        text: message.text,
        ...(this.settings.idempotencyHeader ? {
          headers: { [this.settings.idempotencyHeader]: `auth/${message.deliveryId}` },
        } : {}),
      });
      const accepted = result.accepted?.includes(message.to);
      if (!accepted || result.rejected?.length) throw new Error('Recipient not accepted');
    } catch {
      // SMTP errors often include recipients, headers or credentials. Never propagate them.
      throw new Error('Email delivery failed');
    }
  }

  /** Checks DNS/TLS/auth only. Does not send mail or verify sender/inbox delivery. */
  async verify(): Promise<void> {
    try {
      await this.transport.verify();
    } catch {
      throw new Error('SMTP connection verification failed');
    }
  }

  onApplicationShutdown(): void {
    this.transport.close();
  }
}
