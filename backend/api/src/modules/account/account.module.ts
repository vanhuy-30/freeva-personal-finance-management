import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { AccountController } from './account.controller';
import { AccountService } from './account.service';
import { ACCOUNT_REPOSITORY } from './domain/account.repository';
import { PrismaAccountRepository } from './infrastructure/prisma-account.repository';

@Module({
  imports: [AuthModule],
  controllers: [AccountController],
  providers: [AccountService, { provide: ACCOUNT_REPOSITORY, useClass: PrismaAccountRepository }],
})
export class AccountModule {}
