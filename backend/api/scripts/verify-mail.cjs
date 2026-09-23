// Connection-only probe; never sends email or loads the auth worker/database.
require('reflect-metadata');
const { ConfigModule, ConfigService } = require('@nestjs/config');
const { readMailSettings } = require('../dist/modules/mail/infrastructure/mail-settings');
const { SmtpEmailSender } = require('../dist/modules/mail/infrastructure/smtp-email-sender');

async function main() {
  await ConfigModule.forRoot({ envFilePath: ['.env', '../../.env'] });
  const sender = new SmtpEmailSender(readMailSettings(new ConfigService()));
  try {
    await sender.verify();
    console.log('PASS: SMTP connection/TLS/auth verified. No email was sent.');
  } finally {
    sender.onApplicationShutdown();
  }
}
main().catch(() => {
  // Never dump provider errors, configuration, recipient addresses or secrets.
  console.error('SMTP verification failed. Check mail configuration, DNS/TLS, credentials and provider dashboard.');
  process.exitCode = 1;
});
