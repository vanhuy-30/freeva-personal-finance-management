import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { BILL_REPOSITORY } from './domain/bill.repository';
import { PrismaBillRepository } from './infrastructure/prisma-bill.repository';
import { BillController } from './bill.controller';
import { BillService } from './bill.service';

@Module({
  imports: [AuthModule],
  controllers: [BillController],
  providers: [
    BillService,
    { provide: BILL_REPOSITORY, useClass: PrismaBillRepository },
  ],
  exports: [BillService],
})
export class BillModule {}
