import { CanActivate, ExecutionContext, ForbiddenException, Injectable, SetMetadata } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import type { AuthRequest } from '../auth/auth.guard';
import { AppConfigService } from './app-config.service';
import type { FlagKey } from './domain/app-config-registry';

const FEATURE_KEY = 'freeva:feature';

/** Marks a route (or controller) as needing a server flag; pair with `FeatureGuard` after `AuthGuard`. */
export const RequireFeature = (key: FlagKey) => SetMetadata(FEATURE_KEY, key);

/**
 * Throws 403 `FEATURE_DISABLED` when the flag is off for the caller. Uses an `HttpException` with the
 * error envelope so the filter of whichever module owns the route passes it through unchanged.
 */
@Injectable()
export class FeatureGuard implements CanActivate {
  constructor(private readonly reflector: Reflector, private readonly appConfig: AppConfigService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const key = this.reflector.getAllAndOverride<FlagKey | undefined>(FEATURE_KEY, [context.getHandler(), context.getClass()]);
    if (!key) return true;
    const request = context.switchToHttp().getRequest<AuthRequest>();
    if (!(await this.appConfig.isEnabled(key, request.session.userId))) {
      throw new ForbiddenException({ error: { code: 'FEATURE_DISABLED', message: 'This feature is not enabled', details: [] } });
    }
    return true;
  }
}
