import { Inject, Injectable } from '@nestjs/common';
import { TAG_REPOSITORY, type TagRepository } from './domain/tag.repository';
import type { Tag } from './domain/tag';
import type { CreateTagDto, TagQueryDto, UpdateTagDto } from './tag.dto';
const response = (item: Tag) => ({
  ...item,
  createdAt: item.createdAt.toISOString(),
  updatedAt: item.updatedAt.toISOString(),
});
@Injectable()
export class TagService {
  constructor(@Inject(TAG_REPOSITORY) private readonly repository: TagRepository) {}
  async create(userId: string, dto: CreateTagDto) {
    const result = await this.repository.create(userId, { clientId: dto.clientId, name: dto.name });
    return { tag: response(result.tag), created: result.created };
  }
  async find(userId: string, id: string) { return response(await this.repository.find(userId, id)); }
  async list(userId: string, query: TagQueryDto) {
    const result = await this.repository.list(userId, query);
    return { items: result.items.map(response), total: result.total, page: query.page, pageSize: query.pageSize };
  }
  async update(userId: string, id: string, dto: UpdateTagDto) {
    return response(await this.repository.update(userId, id, dto));
  }
  delete(userId: string, id: string, version: number) { return this.repository.delete(userId, id, version); }
}
