import { Inject, Injectable } from '@nestjs/common';
import { TRANSACTION_REPOSITORY, type TransactionRepository } from './domain/transaction.repository';
import { calendarDate, minor, normalizeRate, TransactionError, type TransactionBundle, type TransactionLeg, type TransactionPatch } from './domain/transaction';
import type { CreateTransactionDto, ManualFxDto, TransactionLegDto, TransactionQueryDto, UpdateTransactionDto } from './transaction.dto';
const legs = (input: TransactionLegDto[]) => input.map(leg => ({ ...leg, amountMinor: minor(leg.amountMinor) }));
const fx = (input: ManualFxDto | null) => input === null ? null : { rate: normalizeRate(input.rate), quotedAt: new Date(input.quotedAt) };
const tags = (ids: string[]) => [...new Set(ids.map(id => id.toLowerCase()))].sort();
function legResponse(leg: TransactionLeg) {
  return { ...leg, amountMinor: leg.amountMinor.toString(), occurredOn: leg.occurredOn.toISOString().slice(0, 10),
    deletedAt: leg.deletedAt?.toISOString() ?? null, createdAt: leg.createdAt.toISOString(), updatedAt: leg.updatedAt.toISOString() };
}
function response(bundle: TransactionBundle) {
  return { legs: bundle.legs.map(legResponse), fx: bundle.fx ? { ...bundle.fx, quotedAt: bundle.fx.quotedAt.toISOString() } : null };
}
@Injectable()
export class TransactionService {
  constructor(@Inject(TRANSACTION_REPOSITORY) private readonly repository: TransactionRepository) {}
  async create(userId: string, dto: CreateTransactionDto) {
    const result = await this.repository.create(userId, { type: dto.type, occurredOn: calendarDate(dto.occurredOn), legs: legs(dto.legs),
      categoryId: dto.categoryId ?? null, notes: dto.notes ?? null, tagIds: tags(dto.tagIds ?? []), fx: fx(dto.fx ?? null) });
    return { transaction: response(result.transaction), created: result.created };
  }
  async find(userId: string, id: string) { return response(await this.repository.find(userId, id)); }
  async list(userId: string, query: TransactionQueryDto) {
    if (query.from) calendarDate(query.from);
    if (query.to) calendarDate(query.to);
    if (query.from && query.to && query.from > query.to) throw new TransactionError('VALIDATION_ERROR');
    const result = await this.repository.list(userId, query);
    return { items: result.items.map(legResponse), total: result.total, page: query.page, pageSize: query.pageSize };
  }
  async update(userId: string, id: string, dto: UpdateTransactionDto) {
    const { occurredOn, legs: inputLegs, fx: inputFx, tagIds, ...rest } = dto;
    const patch: TransactionPatch = { version: dto.version };
    if (rest.categoryId !== undefined) patch.categoryId = rest.categoryId;
    if (rest.notes !== undefined) patch.notes = rest.notes;
    if (rest.deleted !== undefined) patch.deleted = rest.deleted;
    if (occurredOn !== undefined) patch.occurredOn = calendarDate(occurredOn);
    if (inputLegs !== undefined) patch.legs = legs(inputLegs);
    if (inputFx !== undefined) patch.fx = fx(inputFx);
    if (tagIds !== undefined) patch.tagIds = tags(tagIds);
    return response(await this.repository.update(userId, id, patch));
  }
  async delete(userId: string, id: string, version: number): Promise<void> { await this.repository.update(userId, id, { version, deleted: true }); }
}
