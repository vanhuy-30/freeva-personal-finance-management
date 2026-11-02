import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { LOAN_REPOSITORY } from './domain/loan.repository';
import { PrismaLoanRepository } from './infrastructure/prisma-loan.repository';
import { LoanController } from './loan.controller';
import { LoanService } from './loan.service';

@Module({
  imports: [AuthModule],
  controllers: [LoanController],
  providers: [LoanService, { provide: LOAN_REPOSITORY, useClass: PrismaLoanRepository }],
  exports: [LoanService],
})
export class LoanModule {}
