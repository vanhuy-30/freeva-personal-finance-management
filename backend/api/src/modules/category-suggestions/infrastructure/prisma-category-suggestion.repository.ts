import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import type { CategorySuggestionRepository, SuggestionMapping } from '../domain/category-suggestion';

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
}
