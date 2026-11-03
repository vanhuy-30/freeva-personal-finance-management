import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { CardInstallmentController } from './card-installment.controller';
import { CardInstallmentService } from './card-installment.service';
import { CARD_INSTALLMENT_REPOSITORY } from './domain/card-installment.repository';
import { PrismaCardInstallmentRepository } from './infrastructure/prisma-card-installment.repository';

@Module({
  imports: [AuthModule],
  controllers: [CardInstallmentController],
  providers: [CardInstallmentService, { provide: CARD_INSTALLMENT_REPOSITORY, useClass: PrismaCardInstallmentRepository }],
  exports: [CardInstallmentService],
})
export class CardInstallmentModule {}
