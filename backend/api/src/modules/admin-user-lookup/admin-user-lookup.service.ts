import {
  BadRequestException,
  Inject,
  Injectable,
  ServiceUnavailableException,
} from '@nestjs/common';
import {
  AUDIT_EVENT_REPOSITORY,
  type AuditEventRepository,
} from './domain/audit-event.repository';
import type { UserAccountSummary } from './domain/user-account-summary';
import {
  USER_LOOKUP_REPOSITORY,
  type UserLookupRepository,
} from './domain/user-lookup.repository';
import type { StaffUserLookupDto } from './dto/staff-user-lookup.dto';

@Injectable()
export class AdminUserLookupService {
  constructor(
    @Inject(USER_LOOKUP_REPOSITORY)
    private readonly users: UserLookupRepository,
    @Inject(AUDIT_EVENT_REPOSITORY)
    private readonly auditEvents: AuditEventRepository,
  ) {}

  async lookup(
    staffActorId: string,
    criteria: StaffUserLookupDto,
  ): Promise<UserAccountSummary | null> {
    const hasUserId = criteria.userId !== undefined;
    const hasEmail = criteria.email !== undefined;
    if (hasUserId === hasEmail) {
      throw new BadRequestException({
        error: {
          code: 'INVALID_USER_LOOKUP',
          message: 'Provide exactly one of userId or email',
        },
      });
    }

    const user = criteria.userId
      ? await this.users.findById(criteria.userId)
      : await this.users.findByEmail(criteria.email!.trim());

    // Fail closed: do not return PII unless the lookup was audited.
    try {
      await this.auditEvents.recordStaffUserLookup({
        actorId: staffActorId,
        targetId: user?.id ?? null,
        outcome: user ? 'success' : 'failure',
      });
    } catch {
      throw new ServiceUnavailableException({
        error: {
          code: 'AUDIT_UNAVAILABLE',
          message: 'The lookup could not be audited',
        },
      });
    }

    return user;
  }
}
