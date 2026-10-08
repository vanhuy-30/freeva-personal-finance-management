import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { FINANCIAL_ACCOUNT_REPOSITORY } from './domain/financial-account.repository';
import { PrismaFinancialAccountRepository } from './infrastructure/prisma-financial-account.repository';
import { FinancialAccountController } from './financial-account.controller';
import { FinancialAccountService } from './financial-account.service';

@Module({
  imports: [AuthModule],
  controllers: [FinancialAccountController],
  providers: [FinancialAccountService, { provide: FINANCIAL_ACCOUNT_REPOSITORY, useClass: PrismaFinancialAccountRepository }],
})
export class FinancialAccountModule {}
