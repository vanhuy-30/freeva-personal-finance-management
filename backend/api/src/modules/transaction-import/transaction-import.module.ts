import { Module } from '@nestjs/common';
import { AppConfigCoreModule } from '../app-config/app-config-core.module';
import { AuthModule } from '../auth/auth.module';
import { CategorySuggestionModule } from '../category-suggestions/category-suggestion.module';
import { TRANSACTION_IMPORT_REPOSITORY } from './domain/transaction-import.repository';
import { PrismaTransactionImportRepository } from './infrastructure/prisma-transaction-import.repository';
import { TransactionImportController } from './transaction-import.controller';
import { TransactionImportService } from './transaction-import.service';

@Module({
  imports: [AuthModule, AppConfigCoreModule, CategorySuggestionModule],
  controllers: [TransactionImportController],
  providers: [TransactionImportService, { provide: TRANSACTION_IMPORT_REPOSITORY, useClass: PrismaTransactionImportRepository }],
})
export class TransactionImportModule {}
