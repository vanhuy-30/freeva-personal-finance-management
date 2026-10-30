import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import type { FxRate, FxRateRepository } from '../domain/fx-rate.repository';

const select = { fromCode: true, toCode: true, rate: true, quotedAt: true };

function toRate(row: { fromCode: string; toCode: string; rate: { toFixed(digits: number): string }; quotedAt: Date }): FxRate {
  return { fromCode: row.fromCode, toCode: row.toCode, rate: row.rate.toFixed(8), quotedAt: row.quotedAt.toISOString() };
}

@Injectable()
export class PrismaFxRateRepository implements FxRateRepository {
  constructor(private readonly prisma: PrismaService) {}

  async list(userId: string) {
    const rows = await this.prisma.userFxRate.findMany({ where: { userId }, select, orderBy: [{ fromCode: 'asc' }, { toCode: 'asc' }] });
    return rows.map(toRate);
  }

  currencies() {
    return this.prisma.currency.findMany({ select: { code: true, minorDigits: true } });
  }

  async defaultCurrency(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId }, select: { defaultCurrencyCode: true } });
    return user?.defaultCurrencyCode ?? null;
  }

  async upsert(userId: string, rate: FxRate) {
    const data = { rate: rate.rate, quotedAt: new Date(rate.quotedAt) };
    return toRate(await this.prisma.userFxRate.upsert({
      where: { userId_fromCode_toCode: { userId, fromCode: rate.fromCode, toCode: rate.toCode } },
      create: { userId, fromCode: rate.fromCode, toCode: rate.toCode, ...data },
      update: data,
      select,
    }));
  }

  async remove(userId: string, fromCode: string, toCode: string) {
    const removed = await this.prisma.userFxRate.deleteMany({ where: { userId, fromCode, toCode } });
    return removed.count === 1;
  }
}
