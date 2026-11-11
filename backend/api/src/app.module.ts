import { AccountModule } from './modules/account/account.module';
import { SyncModule } from './modules/sync/sync.module';
import { ReportModule } from './modules/reports/report.module';
import { CategoryModule } from './modules/categories/category.module';
import { TagModule } from './modules/tags/tag.module';
import { FeedbackModule } from './modules/feedback/feedback.module';
import { TransactionModule } from './modules/transactions/transaction.module';
import { RecurringModule } from './modules/recurring/recurring.module';
import { BudgetModule } from './modules/budgets/budget.module';
import { GoalModule } from './modules/goals/goal.module';
import { TransactionImportModule } from './modules/transaction-import/transaction-import.module';
import { CardInstallmentModule } from './modules/card-installments/card-installment.module';
import { LoanModule } from './modules/loans/loan.module';
import { InvestmentModule } from './modules/investments/investment.module';
import { PersonalDebtModule } from './modules/personal-debts/personal-debt.module';
import { CalendarModule } from './modules/calendar/calendar.module';
import { ForecastModule } from './modules/forecast/forecast.module';
import { NotificationModule } from './modules/notifications/notification.module';
import { FinancialAccountModule } from './modules/financial-accounts/financial-account.module';
import { FxRateModule } from './modules/fx-rates/fx-rate.module';
import { ProfileModule } from './modules/profile/profile.module';
import { AuthModule } from './modules/auth/auth.module';
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { LoggerModule } from 'nestjs-pino';
import { httpRequestSerializer } from './core/logging/http-request.serializer';
import { pinoRedactOptions } from './core/logging/pino-redact';
import { PrismaModule } from './infrastructure/prisma/prisma.module';
import { AdminUserLookupModule } from './modules/admin-user-lookup/admin-user-lookup.module';
import { HealthModule } from './modules/health/health.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: ['.env', '../../.env'],
    }),
    LoggerModule.forRoot({
      pinoHttp: {
        level: process.env.LOG_LEVEL ?? 'info',
        redact: pinoRedactOptions,
        serializers: { req: httpRequestSerializer },
      },
    }),
    PrismaModule,
    HealthModule,
    AuthModule,
    ProfileModule,
    FxRateModule,
    FinancialAccountModule,
    TransactionModule,
    TransactionImportModule,
    RecurringModule,
    BudgetModule,
    GoalModule,
    LoanModule,
    CardInstallmentModule,
    PersonalDebtModule,
    InvestmentModule,
    CalendarModule,
    ForecastModule,
    NotificationModule,
    SyncModule,
    AccountModule,
    CategoryModule,
    TagModule,
    FeedbackModule,
    ReportModule,
    AdminUserLookupModule,
  ],
})
export class AppModule {}
