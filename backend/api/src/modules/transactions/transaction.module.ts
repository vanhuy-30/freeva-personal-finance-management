import { Module } from '@nestjs/common';
import { AppConfigCoreModule } from '../app-config/app-config-core.module';
import { AuthModule } from '../auth/auth.module';
import { FxRateModule } from '../fx-rates/fx-rate.module';
import { TRANSACTION_REPOSITORY } from './domain/transaction.repository';
import { PrismaTransactionRepository } from './infrastructure/prisma-transaction.repository';
import { ReconcileController } from './reconcile.controller';
import { TransactionController } from './transaction.controller';
import { TransactionService } from './transaction.service';

@Module({
  imports: [AuthModule, FxRateModule, AppConfigCoreModule],
  controllers: [TransactionController, ReconcileController],
  providers: [TransactionService, { provide: TRANSACTION_REPOSITORY, useClass: PrismaTransactionRepository }],
  exports: [TransactionService],
})
export class TransactionModule {}
