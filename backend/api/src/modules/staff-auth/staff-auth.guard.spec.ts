import {
  ExecutionContext,
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import type { Request } from 'express';
import { StaffAuthGuard } from './staff-auth.guard';
import type { StaffRequest } from './staff-principal';

const staffId = '11111111-1111-4111-8111-111111111111';
const staffToken = 'test-staff-token-at-least-32-characters';

describe('StaffAuthGuard', () => {
  it('accepts the configured bearer token and attaches the staff principal', () => {
    const request = requestWithAuthorization(`Bearer ${staffToken}`);
    const guard = createGuard({
      STAFF_AUTH_TOKEN: staffToken,
      STAFF_ACTOR_ID: staffId,
    });

    expect(guard.canActivate(contextFor(request))).toBe(true);
    expect((request as StaffRequest).staff).toEqual({
      id: staffId,
      role: 'staff',
    });
  });

  it('rejects a missing or incorrect credential without echoing it', () => {
    const guard = createGuard({
      STAFF_AUTH_TOKEN: staffToken,
      STAFF_ACTOR_ID: staffId,
    });
    const request = requestWithAuthorization('Bearer wrong-secret');

    expect(() => guard.canActivate(contextFor(request))).toThrow(
      UnauthorizedException,
    );
    try {
      guard.canActivate(contextFor(request));
    } catch (error) {
      expect(JSON.stringify(error)).not.toContain('wrong-secret');
      expect(JSON.stringify(error)).not.toContain(staffToken);
    }
  });

  it('fails closed when staff authentication is not configured', () => {
    const guard = createGuard({});

    expect(() =>
      guard.canActivate(contextFor(requestWithAuthorization(undefined))),
    ).toThrow(ServiceUnavailableException);
  });

  it('rejects the committed placeholder credential as configuration', () => {
    const guard = createGuard({
      STAFF_AUTH_TOKEN: 'replace-with-a-long-random-token',
      STAFF_ACTOR_ID: staffId,
    });

    expect(() =>
      guard.canActivate(contextFor(requestWithAuthorization(undefined))),
    ).toThrow(ServiceUnavailableException);
  });
});

function createGuard(config: Record<string, string>): StaffAuthGuard {
  return new StaffAuthGuard(new ConfigService(config));
}

function requestWithAuthorization(authorization: string | undefined): Request {
  return {
    headers: authorization ? { authorization } : {},
  } as Request;
}

function contextFor(request: Request): ExecutionContext {
  return {
    switchToHttp: () => ({
      getRequest: () => request,
    }),
  } as ExecutionContext;
}
