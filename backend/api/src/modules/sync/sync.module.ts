import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { TransactionModule } from '../transactions/transaction.module';
import { SYNC_REPOSITORY } from './domain/sync.repository';
import { PrismaSyncRepository } from './infrastructure/prisma-sync.repository';
import { SyncController } from './sync.controller';
import { SyncService } from './sync.service';

@Module({
  imports: [AuthModule, TransactionModule],
  controllers: [SyncController],
  providers: [SyncService, { provide: SYNC_REPOSITORY, useClass: PrismaSyncRepository }],
})
export class SyncModule {}
