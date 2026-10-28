import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { BudgetController } from './budget.controller';
import { BudgetService } from './budget.service';
import { BUDGET_REPOSITORY } from './domain/budget.repository';
import { PrismaBudgetRepository } from './infrastructure/prisma-budget.repository';

@Module({
  imports: [AuthModule],
  controllers: [BudgetController],
  providers: [
    BudgetService,
    { provide: BUDGET_REPOSITORY, useClass: PrismaBudgetRepository },
  ],
  exports: [BudgetService],
})
export class BudgetModule {}
