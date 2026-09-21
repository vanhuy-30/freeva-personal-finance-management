import {
  CanActivate,
  ExecutionContext,
  HttpException,
  Inject,
  Injectable,
} from '@nestjs/common';
import type { Request, Response } from 'express';
import { AUTH_REPOSITORY, type AuthRepository } from './domain/auth.repository';
import { AuthCrypto } from './infrastructure/auth-crypto';

@Injectable()
export class AuthRateLimitGuard implements CanActivate {
  constructor(
    @Inject(AUTH_REPOSITORY) private readonly repository: AuthRepository,
    private readonly crypto: AuthCrypto,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<Request>();
    const response = context.switchToHttp().getResponse<Response>();
    const operation = context.getHandler().name;
    // Express trust proxy defaults to false: never accept arbitrary forwarded IPs.
    const retryIp = await this.repository.takeRateLimit(
      this.crypto.rateKey(`ip:${operation}:${request.ip}`),
      30,
      900,
    );
    let retryEmail = 0;
    if (
      retryIp === 0 &&
      typeof request.body?.email === 'string' &&
      request.body.email.length <= 1024
    ) {
      const email = request.body.email.trim().toLowerCase();
      retryEmail = await this.repository.takeRateLimit(
        this.crypto.rateKey(`email:${operation}:${email}`),
        5,
        900,
      );
    }
    const retry = Math.max(retryIp, retryEmail);
    if (retry > 0) {
      response.setHeader('Retry-After', String(retry));
      throw new HttpException(
        {
          error: {
            code: 'RATE_LIMITED',
            message: 'Too many attempts. Try again later.',
          },
        },
        429,
      );
    }
    return true;
  }
}
