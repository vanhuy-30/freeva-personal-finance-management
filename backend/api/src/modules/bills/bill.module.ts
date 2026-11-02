import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { BillController } from './bill.controller';

@Module({
  imports: [AuthModule],
  controllers: [BillController],
})
export class BillModule {}
