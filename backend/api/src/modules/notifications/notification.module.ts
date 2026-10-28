import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { NOTIFICATION_REPOSITORY } from './domain/notification.repository';
import { NotificationWorker } from './infrastructure/notification.worker';
import { PrismaNotificationRepository } from './infrastructure/prisma-notification.repository';
import { NotificationController } from './notification.controller';
import { NotificationService } from './notification.service';

@Module({
  imports: [AuthModule],
  controllers: [NotificationController],
  providers: [
    NotificationService,
    NotificationWorker,
    { provide: NOTIFICATION_REPOSITORY, useClass: PrismaNotificationRepository },
  ],
  exports: [NotificationService],
})
export class NotificationModule {}
