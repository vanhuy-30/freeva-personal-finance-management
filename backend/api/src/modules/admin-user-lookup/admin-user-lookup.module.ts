import { Module } from '@nestjs/common';
import { StaffAuthGuard } from '../staff-auth/staff-auth.guard';
import { AdminUserLookupController } from './admin-user-lookup.controller';
import { AdminUserLookupService } from './admin-user-lookup.service';
import { AUDIT_EVENT_REPOSITORY } from './domain/audit-event.repository';
import { USER_LOOKUP_REPOSITORY } from './domain/user-lookup.repository';
import { PrismaAuditEventRepository } from './infrastructure/prisma-audit-event.repository';
import { PrismaUserLookupRepository } from './infrastructure/prisma-user-lookup.repository';

@Module({
  controllers: [AdminUserLookupController],
  providers: [
    StaffAuthGuard,
    AdminUserLookupService,
    {
      provide: USER_LOOKUP_REPOSITORY,
      useClass: PrismaUserLookupRepository,
    },
    {
      provide: AUDIT_EVENT_REPOSITORY,
      useClass: PrismaAuditEventRepository,
    },
  ],
})
export class AdminUserLookupModule {}
