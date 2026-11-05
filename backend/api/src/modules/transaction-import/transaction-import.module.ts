import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { TRANSACTION_IMPORT_REPOSITORY } from './domain/transaction-import.repository';
import { PrismaTransactionImportRepository } from './infrastructure/prisma-transaction-import.repository';
import { TransactionImportController } from './transaction-import.controller';
import { TransactionImportService } from './transaction-import.service';

@Module({
  imports: [AuthModule],
  controllers: [TransactionImportController],
  providers: [TransactionImportService, { provide: TRANSACTION_IMPORT_REPOSITORY, useClass: PrismaTransactionImportRepository }],
})
export class TransactionImportModule {}
