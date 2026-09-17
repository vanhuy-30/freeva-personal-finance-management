import {
  BadRequestException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { AdminUserLookupService } from './admin-user-lookup.service';
import type { AuditEventRepository } from './domain/audit-event.repository';
import type { UserAccountSummary } from './domain/user-account-summary';
import type { UserLookupRepository } from './domain/user-lookup.repository';

const staffActorId = '11111111-1111-4111-8111-111111111111';
const user: UserAccountSummary = {
  id: '22222222-2222-4222-8222-222222222222',
  email: 'member@example.com',
  locale: 'vi',
  timezone: 'Asia/Ho_Chi_Minh',
  defaultCurrencyCode: 'VND',
  fiscalMonthStartDay: 1,
  createdAt: new Date('2026-09-17T00:00:00.000Z'),
};

describe('AdminUserLookupService', () => {
  let users: jest.Mocked<UserLookupRepository>;
  let auditEvents: jest.Mocked<AuditEventRepository>;
  let service: AdminUserLookupService;

  beforeEach(() => {
    users = {
      findById: jest.fn(),
      findByEmail: jest.fn(),
    };
    auditEvents = {
      recordStaffUserLookup: jest.fn().mockResolvedValue(undefined),
    };
    service = new AdminUserLookupService(users, auditEvents);
  });

  it('returns the minimum account profile and audits a successful lookup', async () => {
    users.findByEmail.mockResolvedValue(user);

    await expect(
      service.lookup(staffActorId, { email: ' member@example.com ' }),
    ).resolves.toEqual(user);
    expect(users.findByEmail).toHaveBeenCalledWith('member@example.com');
    expect(auditEvents.recordStaffUserLookup).toHaveBeenCalledWith({
      actorId: staffActorId,
      targetId: user.id,
      outcome: 'success',
    });
  });

  it('audits a lookup that has no match', async () => {
    users.findById.mockResolvedValue(null);

    await expect(
      service.lookup(staffActorId, { userId: user.id }),
    ).resolves.toBeNull();
    expect(auditEvents.recordStaffUserLookup).toHaveBeenCalledWith({
      actorId: staffActorId,
      targetId: null,
      outcome: 'failure',
    });
  });

  it('does not return PII when the audit write fails', async () => {
    users.findById.mockResolvedValue(user);
    auditEvents.recordStaffUserLookup.mockRejectedValue(
      new Error('audit unavailable'),
    );

    await expect(
      service.lookup(staffActorId, { userId: user.id }),
    ).rejects.toBeInstanceOf(ServiceUnavailableException);
  });

  it('requires exactly one lookup criterion', async () => {
    await expect(service.lookup(staffActorId, {})).rejects.toBeInstanceOf(
      BadRequestException,
    );
    await expect(
      service.lookup(staffActorId, { userId: user.id, email: user.email }),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(users.findById).not.toHaveBeenCalled();
    expect(users.findByEmail).not.toHaveBeenCalled();
  });
});
