import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { RECURRING_REPOSITORY } from './domain/recurring.repository';
import { PrismaRecurringRepository } from './infrastructure/prisma-recurring.repository';
import { RecurringWorker } from './infrastructure/recurring.worker';
import { RecurringController } from './recurring.controller';
import { RecurringService } from './recurring.service';

@Module({
  imports: [AuthModule],
  controllers: [RecurringController],
  providers: [
    RecurringService,
    RecurringWorker,
    { provide: RECURRING_REPOSITORY, useClass: PrismaRecurringRepository },
  ],
  exports: [RecurringService],
})
export class RecurringModule {}
