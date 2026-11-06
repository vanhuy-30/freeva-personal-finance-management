import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { INVESTMENT_REPOSITORY } from './domain/investment.repository';
import { PrismaInvestmentRepository } from './infrastructure/prisma-investment.repository';
import { InvestmentController } from './investment.controller';
import { InvestmentService } from './investment.service';

@Module({
  imports: [AuthModule],
  controllers: [InvestmentController],
  providers: [InvestmentService, { provide: INVESTMENT_REPOSITORY, useClass: PrismaInvestmentRepository }],
  exports: [InvestmentService],
})
export class InvestmentModule {}
