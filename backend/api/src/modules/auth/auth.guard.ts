import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';
import type { Request } from 'express';
import type { Session } from './domain/auth.repository';
import { AuthService, unauthorized } from './auth.service';

export type AuthRequest = Request & { session: Session };

@Injectable()
export class AuthGuard implements CanActivate {
  constructor(private readonly auth: AuthService) {}
  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<AuthRequest>();
    const match = /^Bearer ([a-f0-9]{64})$/i.exec(
      request.headers.authorization ?? '',
    );
    if (!match) throw unauthorized();
    request.session = await this.auth.authenticate(match[1]);
    return true;
  }
}
