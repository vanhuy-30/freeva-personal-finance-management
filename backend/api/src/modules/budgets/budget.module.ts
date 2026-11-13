import { Module } from '@nestjs/common';
import { AppConfigCoreModule } from '../app-config/app-config-core.module';
import { AuthModule } from '../auth/auth.module';
import { BudgetController } from './budget.controller';
import { BudgetService } from './budget.service';
import { BUDGET_REPOSITORY } from './domain/budget.repository';
import { PrismaBudgetRepository } from './infrastructure/prisma-budget.repository';

@Module({
  imports: [AuthModule, AppConfigCoreModule],
  controllers: [BudgetController],
  providers: [
    BudgetService,
    { provide: BUDGET_REPOSITORY, useClass: PrismaBudgetRepository },
  ],
  exports: [BudgetService],
})
export class BudgetModule {}
