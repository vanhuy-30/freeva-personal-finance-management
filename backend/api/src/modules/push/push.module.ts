import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { AuthModule } from '../auth/auth.module';
import { PUSH_DISPATCHER, PUSH_SENDER } from './domain/push-sender';
import { PUSH_TOKEN_REPOSITORY } from './domain/push-token.repository';
import { DisabledPushSender, FcmPushSender } from './infrastructure/fcm-push-sender';
import { PrismaPushTokenRepository } from './infrastructure/prisma-push-token.repository';
import { readPushSettings } from './infrastructure/push-settings';
import { PushController } from './push.controller';
import { PushService } from './push.service';

@Module({
  imports: [ConfigModule, AuthModule],
  controllers: [PushController],
  providers: [
    PushService,
    { provide: PUSH_TOKEN_REPOSITORY, useClass: PrismaPushTokenRepository },
    {
      provide: PUSH_SENDER,
      inject: [ConfigService],
      useFactory: (config: ConfigService) => {
        const settings = readPushSettings(config);
        return settings ? new FcmPushSender(settings) : new DisabledPushSender();
      },
    },
    { provide: PUSH_DISPATCHER, useExisting: PushService },
  ],
  exports: [PUSH_DISPATCHER],
})
export class PushModule {}
