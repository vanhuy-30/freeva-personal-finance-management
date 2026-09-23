import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { EMAIL_SENDER } from './domain/email-sender';
import { readMailSettings } from './infrastructure/mail-settings';
import { SmtpEmailSender } from './infrastructure/smtp-email-sender';

@Module({
  imports: [ConfigModule],
  providers: [{
    provide: EMAIL_SENDER,
    inject: [ConfigService],
    useFactory: (config: ConfigService) => new SmtpEmailSender(readMailSettings(config)),
  }],
  exports: [EMAIL_SENDER],
})
export class MailModule {}
