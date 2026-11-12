import { Module } from '@nestjs/common';
import { AppConfigCoreModule } from '../app-config/app-config-core.module';
import { AuthModule } from '../auth/auth.module';
import { BudgetModule } from '../budgets/budget.module';
import { CategorySuggestionModule } from '../category-suggestions/category-suggestion.module';
import { SPEND_FORECAST_REPOSITORY } from './domain/spend-forecast.repository';
import { PrismaSpendForecastRepository } from './infrastructure/prisma-spend-forecast.repository';
import { GoalForecastController, SpendForecastController } from './spend-forecast.controller';
import { SpendForecastService } from './spend-forecast.service';

@Module({
  imports: [AuthModule, AppConfigCoreModule, BudgetModule, CategorySuggestionModule],
  controllers: [SpendForecastController, GoalForecastController],
  providers: [SpendForecastService, { provide: SPEND_FORECAST_REPOSITORY, useClass: PrismaSpendForecastRepository }],
})
export class SpendForecastModule {}
