import { timingSafeEqual } from 'node:crypto';
import {
  CanActivate,
  ExecutionContext,
  Injectable,
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { isUUID } from 'class-validator';
import type { Request } from 'express';
import type { StaffRequest } from './staff-principal';

const staffTokenPlaceholder = 'replace-with-a-long-random-token';

@Injectable()
export class StaffAuthGuard implements CanActivate {
  constructor(private readonly config: ConfigService) {}

  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest<Request>();
    const configuredToken = this.config.get<string>('STAFF_AUTH_TOKEN');
    const staffActorId = this.config.get<string>('STAFF_ACTOR_ID');

    if (
      !configuredToken ||
      configuredToken.length < 32 ||
      configuredToken === staffTokenPlaceholder ||
      !staffActorId ||
      !isUUID(staffActorId)
    ) {
      throw new ServiceUnavailableException({
        error: {
          code: 'STAFF_AUTH_NOT_CONFIGURED',
          message: 'Staff authentication is not configured',
        },
      });
    }

    const suppliedToken = this.readBearerToken(request);
    if (!suppliedToken || !this.tokensMatch(suppliedToken, configuredToken)) {
      throw new UnauthorizedException({
        error: {
          code: 'STAFF_AUTH_INVALID',
          message: 'Staff authentication failed',
        },
      });
    }

    (request as StaffRequest).staff = {
      id: staffActorId,
      role: 'staff',
    };
    return true;
  }

  private readBearerToken(request: Request): string | null {
    const authorization = request.headers.authorization;
    if (!authorization?.startsWith('Bearer ')) {
      return null;
    }

    const token = authorization.slice('Bearer '.length);
    return token.length > 0 ? token : null;
  }

  private tokensMatch(supplied: string, configured: string): boolean {
    const suppliedBuffer = Buffer.from(supplied);
    const configuredBuffer = Buffer.from(configured);
    return (
      suppliedBuffer.length === configuredBuffer.length &&
      timingSafeEqual(suppliedBuffer, configuredBuffer)
    );
  }
}
