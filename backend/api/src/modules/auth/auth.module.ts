import { OAuthService } from './oauth.service';
import { OAUTH_REPOSITORY, OAUTH_VERIFIER } from './domain/oauth';
import { OidcVerifier } from './infrastructure/oidc-verifier';
import { PrismaOAuthRepository } from './infrastructure/prisma-oauth.repository';
import { Module } from '@nestjs/common';
import { MailModule } from '../mail/mail.module';
import { AUTH_REPOSITORY } from './domain/auth.repository';
import { AuthController, SessionsController } from './auth.controller';
import { AuthService } from './auth.service';
import { AuthGuard } from './auth.guard';
import { AuthRateLimitGuard } from './auth-rate-limit.guard';
import { AuthCrypto } from './infrastructure/auth-crypto';
import { PrismaAuthRepository } from './infrastructure/prisma-auth.repository';
import { AuthMailWorker } from './infrastructure/auth-mail.worker';

@Module({
  imports: [MailModule],
  controllers: [AuthController, SessionsController],
  providers: [
    AuthService,
    OAuthService,
    { provide: OAUTH_REPOSITORY, useClass: PrismaOAuthRepository },
    { provide: OAUTH_VERIFIER, useClass: OidcVerifier },
    AuthGuard,
    AuthRateLimitGuard,
    AuthCrypto,
    AuthMailWorker,
    { provide: AUTH_REPOSITORY, useClass: PrismaAuthRepository },
  ],
  exports: [AuthGuard, AuthService],
})
export class AuthModule {}
