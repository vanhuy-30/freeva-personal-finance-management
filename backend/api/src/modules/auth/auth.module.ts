import { Module } from '@nestjs/common';
import { AUTH_REPOSITORY } from './domain/auth.repository';
import { AuthController, SessionsController } from './auth.controller';
import { AuthService } from './auth.service';
import { AuthGuard } from './auth.guard';
import { AuthRateLimitGuard } from './auth-rate-limit.guard';
import { AuthCrypto } from './infrastructure/auth-crypto';
import { PrismaAuthRepository } from './infrastructure/prisma-auth.repository';
import { AuthMailWorker } from './infrastructure/auth-mail.worker';

@Module({
  controllers: [AuthController, SessionsController],
  providers: [
    AuthService,
    AuthGuard,
    AuthRateLimitGuard,
    AuthCrypto,
    AuthMailWorker,
    { provide: AUTH_REPOSITORY, useClass: PrismaAuthRepository },
  ],
  exports: [AuthGuard, AuthService],
})
export class AuthModule {}
