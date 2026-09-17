import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import type {
  AuditEventRepository,
  StaffUserLookupAudit,
} from '../domain/audit-event.repository';

@Injectable()
export class PrismaAuditEventRepository implements AuditEventRepository {
  constructor(private readonly prisma: PrismaService) {}

  async recordStaffUserLookup(event: StaffUserLookupAudit): Promise<void> {
    await this.prisma.auditEvent.create({
      data: {
        actorType: 'staff',
        actorId: event.actorId,
        action: 'staff.user_lookup',
        targetType: 'user',
        targetId: event.targetId,
        outcome: event.outcome,
      },
    });
  }
}
