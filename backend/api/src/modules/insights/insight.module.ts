import { Module } from '@nestjs/common';
import { AppConfigCoreModule } from '../app-config/app-config-core.module';
import { AuthModule } from '../auth/auth.module';
import { BudgetModule } from '../budgets/budget.module';
import { CategorySuggestionModule } from '../category-suggestions/category-suggestion.module';
import { INSIGHT_REPOSITORY } from './domain/insight.repository';
import { PrismaInsightRepository } from './infrastructure/prisma-insight.repository';
import { InsightController } from './insight.controller';
import { InsightService } from './insight.service';

@Module({
  imports: [AuthModule, AppConfigCoreModule, BudgetModule, CategorySuggestionModule],
  controllers: [InsightController],
  providers: [InsightService, { provide: INSIGHT_REPOSITORY, useClass: PrismaInsightRepository }],
})
export class InsightModule {}
