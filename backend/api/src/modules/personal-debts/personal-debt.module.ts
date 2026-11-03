import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { PERSONAL_DEBT_REPOSITORY } from './domain/personal-debt.repository';
import { PrismaPersonalDebtRepository } from './infrastructure/prisma-personal-debt.repository';
import { PersonalDebtController } from './personal-debt.controller';
import { PersonalDebtService } from './personal-debt.service';

@Module({
  imports: [AuthModule],
  controllers: [PersonalDebtController],
  providers: [PersonalDebtService, { provide: PERSONAL_DEBT_REPOSITORY, useClass: PrismaPersonalDebtRepository }],
  exports: [PersonalDebtService],
})
export class PersonalDebtModule {}
