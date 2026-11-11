import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import {
  merchantKey,
  type CategorySuggestionRepository,
  type SuggestOutcome,
  type SuggestSurface,
  type SuggestionMapping,
  type SuggestionStatRow,
} from '../domain/category-suggestion';
import type { SuggestCategory, SuggestKind, SuggestionSource } from '../domain/suggest';

@Injectable()
export class PrismaCategorySuggestionRepository implements CategorySuggestionRepository {
  constructor(private readonly prisma: PrismaService) {}

  async autoSuggestEnabled(userId: string): Promise<boolean | null> {
    const user = await this.prisma.user.findUnique({ where: { id: userId }, select: { autoSuggestEnabled: true } });
    return user?.autoSuggestEnabled ?? null;
  }

  async listMappings(userId: string): Promise<SuggestionMapping[]> {
    const rows = await this.prisma.categorySuggestionMapping.findMany({
      where: { userId },
      orderBy: [{ updatedAt: 'desc' }, { id: 'asc' }],
      select: {
        id: true, merchant: true, updatedAt: true,
        category: { select: { id: true, name: true, iconToken: true, colorToken: true } },
      },
    });
    return rows;
  }

  async deleteMapping(userId: string, id: string): Promise<boolean> {
    const removed = await this.prisma.categorySuggestionMapping.deleteMany({ where: { id, userId } });
    return removed.count === 1;
  }

  async deleteAllMappings(userId: string): Promise<number> {
    return (await this.prisma.categorySuggestionMapping.deleteMany({ where: { userId } })).count;
  }

  async rememberedCategoryId(userId: string, key: string): Promise<string | null> {
    const row = await this.prisma.categorySuggestionMapping.findUnique({
      where: { userId_merchantKey: { userId, merchantKey: key } }, select: { categoryId: true },
    });
    return row?.categoryId ?? null;
  }

  async historyCategoryIds(userId: string, match: { merchant: string | null; note: string | null }, kind: SuggestKind, limit: number) {
    const field = match.merchant ? 'merchant' : 'notes';
    const text = (match.merchant ?? match.note ?? '').trim();
    if (!text) return [];
    const key = merchantKey(text);
    // Case-insensitive equality on the first word narrows the scan; exact key comparison happens below.
    const rows = await this.prisma.transaction.findMany({
      where: {
        userId, type: kind, deletedAt: null, categoryId: { not: null },
        [field]: { startsWith: text.split(/\s+/)[0], mode: 'insensitive' },
      },
      orderBy: [{ occurredOn: 'desc' }, { createdAt: 'desc' }],
      select: { categoryId: true, merchant: true, notes: true },
      take: limit * 4,
    });
    return rows
      .filter(row => merchantKey((field === 'merchant' ? row.merchant : row.notes) ?? '') === key)
      .slice(0, limit)
      .map(row => row.categoryId!);
  }

  async categories(userId: string): Promise<SuggestCategory[]> {
    return this.prisma.category.findMany({
      where: { userId },
      select: { id: true, name: true, iconToken: true, colorToken: true, kind: true, isSystem: true, parentId: true, archivedAt: true },
    });
  }

  async remember(userId: string, merchant: string, categoryId: string): Promise<void> {
    const shown = merchant.trim().replace(/\s+/g, ' ').slice(0, 200);
    await this.prisma.categorySuggestionMapping.upsert({
      where: { userId_merchantKey: { userId, merchantKey: merchantKey(shown) } },
      create: { userId, merchantKey: merchantKey(shown), merchant: shown, categoryId },
      update: { merchant: shown, categoryId },
    });
  }

  async count(day: Date, surface: SuggestSurface, source: SuggestionSource, outcome: SuggestOutcome): Promise<void> {
    await this.prisma.categorySuggestionStat.upsert({
      where: { day_surface_source: { day, surface, source } },
      create: { day, surface, source, [outcome]: 1 },
      update: { [outcome]: { increment: 1 } },
    });
  }

  async stats(from: Date, to: Date): Promise<SuggestionStatRow[]> {
    const rows = await this.prisma.categorySuggestionStat.findMany({
      where: { day: { gte: from, lte: to } },
      orderBy: [{ day: 'asc' }, { surface: 'asc' }, { source: 'asc' }],
    });
    return rows.map(row => ({
      day: row.day.toISOString().slice(0, 10),
      surface: row.surface as SuggestSurface,
      source: row.source as SuggestionSource,
      accepted: row.accepted,
      corrected: row.corrected,
    }));
  }
}
