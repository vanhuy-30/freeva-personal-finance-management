import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import { AppConfigError, type FlagState } from '../domain/app-config';
import type {
  AppConfigRepository,
  AppConfigSnapshot,
  StoredFlag,
  StoredValue,
} from '../domain/app-config.repository';

type Tx = Prisma.TransactionClient;

const flagJson = (state: FlagState) => ({
  enabled: state.enabled, userIds: [...state.userIds], percentage: state.percentage,
});

@Injectable()
export class PrismaAppConfigRepository implements AppConfigRepository {
  constructor(private readonly prisma: PrismaService) {}

  async snapshot(): Promise<AppConfigSnapshot> {
    const [meta, flags, values] = await Promise.all([
      this.prisma.appConfigMeta.findUnique({ where: { id: 1 } }),
      this.prisma.featureFlag.findMany(),
      this.prisma.appConfigValue.findMany(),
    ]);
    return { version: meta?.version ?? 1, flags, values };
  }

  saveFlag(input: { key: string; state: FlagState; expectedVersion: number; actorId: string }): Promise<StoredFlag> {
    return this.prisma.$transaction(async (tx) => {
      const current = await tx.featureFlag.findUnique({ where: { key: input.key } });
      if ((current?.version ?? 0) !== input.expectedVersion) throw new AppConfigError('CONFIG_CONFLICT');
      const data = { ...flagJson(input.state), updatedBy: input.actorId };
      const saved = current
        ? await this.updateOrConflict(() => tx.featureFlag.update({
          where: { key: input.key, version: input.expectedVersion }, data: { ...data, version: { increment: 1 } },
        }))
        : await this.createOrConflict(() => tx.featureFlag.create({ data: { key: input.key, ...data } }));
      await this.record(tx, 'flag', input.key, current ? flagJson(current) : null, flagJson(input.state), input.actorId);
      return saved;
    });
  }

  saveValue(input: { key: string; value: unknown; expectedVersion: number; actorId: string }): Promise<StoredValue> {
    return this.prisma.$transaction(async (tx) => {
      const current = await tx.appConfigValue.findUnique({ where: { key: input.key } });
      if ((current?.version ?? 0) !== input.expectedVersion) throw new AppConfigError('CONFIG_CONFLICT');
      const value = input.value as Prisma.InputJsonValue;
      const saved = current
        ? await this.updateOrConflict(() => tx.appConfigValue.update({
          where: { key: input.key, version: input.expectedVersion },
          data: { value, updatedBy: input.actorId, version: { increment: 1 } },
        }))
        : await this.createOrConflict(() => tx.appConfigValue.create({
          data: { key: input.key, value, updatedBy: input.actorId },
        }));
      await this.record(tx, 'value', input.key, current?.value ?? null, input.value, input.actorId);
      return saved;
    });
  }

  resetValue(input: { key: string; expectedVersion: number; actorId: string }): Promise<void> {
    return this.prisma.$transaction(async (tx) => {
      const current = await tx.appConfigValue.findUnique({ where: { key: input.key } });
      if (!current || current.version !== input.expectedVersion) throw new AppConfigError('CONFIG_CONFLICT');
      const removed = await tx.appConfigValue.deleteMany({ where: { key: input.key, version: input.expectedVersion } });
      if (removed.count !== 1) throw new AppConfigError('CONFIG_CONFLICT');
      await this.record(tx, 'value', input.key, current.value, null, input.actorId);
    });
  }

  private async record(tx: Tx, kind: 'flag' | 'value', key: string, before: unknown, after: unknown, actorId: string) {
    const json = (value: unknown) => (value === null ? Prisma.DbNull : (value as Prisma.InputJsonValue));
    await tx.appConfigChange.create({ data: { kind, key, before: json(before), after: json(after), actorId } });
    await tx.auditEvent.create({
      data: {
        actorType: 'staff', actorId, action: 'staff.app_config_update', targetType: 'app_config', outcome: 'success',
      },
    });
    await tx.appConfigMeta.upsert({
      where: { id: 1 }, create: { id: 1, version: 2 }, update: { version: { increment: 1 } },
    });
  }

  /** A concurrent writer moved the version between our read and update. */
  private async updateOrConflict<T>(write: () => Promise<T>): Promise<T> {
    try {
      return await write();
    } catch (error) {
      if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2025') {
        throw new AppConfigError('CONFIG_CONFLICT');
      }
      throw error;
    }
  }

  /** A concurrent writer created the row first. */
  private async createOrConflict<T>(write: () => Promise<T>): Promise<T> {
    try {
      return await write();
    } catch (error) {
      if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
        throw new AppConfigError('CONFIG_CONFLICT');
      }
      throw error;
    }
  }
}
