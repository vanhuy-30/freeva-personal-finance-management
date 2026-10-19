import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import type { SyncRepository } from '../domain/sync.repository';

@Injectable()
export class PrismaSyncRepository implements SyncRepository {
  constructor(private readonly prisma: PrismaService) {}
  async schemaVersion(): Promise<number | null> {
    return (await this.prisma.schemaMeta.findUnique({ where: { id: 1 } }))?.version ?? null;
  }
}
