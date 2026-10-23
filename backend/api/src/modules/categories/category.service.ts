import { Inject, Injectable } from '@nestjs/common';
import { CATEGORY_REPOSITORY, type CategoryRepository } from './domain/category.repository';
import { assertPaletteColor, CATEGORY_PALETTE, CATEGORY_PICKER_ICONS, CategoryError, type Category } from './domain/category';
import type { CategoryQueryDto, CreateCategoryDto, UpdateCategoryDto } from './category.dto';
import { CATEGORY_COLORS } from './category-tokens.generated';
const response = (item: Category) => ({ ...item, archivedAt: item.archivedAt?.toISOString() ?? null,
  createdAt: item.createdAt.toISOString(), updatedAt: item.updatedAt.toISOString() });
@Injectable()
export class CategoryService {
  constructor(@Inject(CATEGORY_REPOSITORY) private readonly repository: CategoryRepository) {}
  /** Picker choices in display order; older catalog keys and icons stay valid on rows that have them. */
  options() { return { colorTokens: CATEGORY_PALETTE, iconTokens: CATEGORY_PICKER_ICONS }; }
  private validateColor(color: string | null | undefined) {
    if (color != null && !(CATEGORY_COLORS as readonly string[]).includes(color)) throw new CategoryError('VALIDATION_ERROR');
  }
  initialize(userId: string) { return this.repository.initialize(userId); }
  async create(userId: string, dto: CreateCategoryDto) {
    this.validateColor(dto.colorToken);
    assertPaletteColor(dto.colorToken);
    const result = await this.repository.create(userId, { clientId: dto.clientId, name: dto.name,
      parentId: dto.parentId ?? null, colorToken: dto.colorToken ?? null, iconToken: dto.iconToken ?? null,
      kind: dto.kind ?? 'both' });
    return { category: response(result.category), created: result.created };
  }
  async find(userId: string, id: string) { return response(await this.repository.find(userId, id)); }
  async list(userId: string, query: CategoryQueryDto) {
    const result = await this.repository.list(userId, query);
    return { items: result.items.map(response), total: result.total, page: query.page, pageSize: query.pageSize };
  }
  async recent(userId: string) { return { items: (await this.repository.recent(userId)).map(response) }; }
  async update(userId: string, id: string, dto: UpdateCategoryDto) {
    this.validateColor(dto.colorToken);
    return response(await this.repository.update(userId, id, dto));
  }
  async usage(userId: string, id: string) { return { transactionCount: await this.repository.transactionCount(userId, id) }; }
  delete(userId: string, id: string, version: number, replacement?: string) { return this.repository.delete(userId, id, version, replacement); }
}
