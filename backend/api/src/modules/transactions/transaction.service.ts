import { Inject, Injectable } from '@nestjs/common';
import { TRANSACTION_REPOSITORY, type RecentMatchQuery, type TransactionRepository } from './domain/transaction.repository';
import { buildTransactionsCsv, CSV_EXPORT_MAX_ROWS } from './domain/csv-export';
import { calendarDate, minor, normalizeRate, occurredTime, TransactionError, type RefundDisposition, type TransactionBundle, type TransactionLeg, type TransactionPatch } from './domain/transaction';
import { FxRateService } from '../fx-rates/fx-rate.service';
import type { ReconcileResult } from './domain/reconcile';
import type { CreateTransactionDto, ReconcileDto, RefundDto, ManualFxDto, TransactionLegDto, TransactionCsvQueryDto, TransactionQueryDto, UpdateTransactionDto } from './transaction.dto';
const legs = (input: TransactionLegDto[]) => input.map(leg => ({ ...leg, amountMinor: minor(leg.amountMinor) }));
const fx = (input: ManualFxDto | null) => input === null ? null : { rate: normalizeRate(input.rate), quotedAt: new Date(input.quotedAt) };
const tags = (ids: string[]) => [...new Set(ids.map(id => id.toLowerCase()))].sort();
function legResponse(leg: TransactionLeg) {
  return { ...leg, amountMinor: leg.amountMinor.toString(), occurredOn: leg.occurredOn.toISOString().slice(0, 10),
    occurredTime: leg.occurredTime, deletedAt: leg.deletedAt?.toISOString() ?? null,
    createdAt: leg.createdAt.toISOString(), updatedAt: leg.updatedAt.toISOString() };
}
function response(bundle: TransactionBundle) {
  return { legs: bundle.legs.map(legResponse), fx: bundle.fx ? { ...bundle.fx, quotedAt: bundle.fx.quotedAt.toISOString() } : null };
}
function reconcileResponse(result: ReconcileResult) {
  return { accountId: result.accountId, currencyCode: result.currencyCode, currentBalanceMinor: result.currentBalanceMinor.toString(),
    targetBalanceMinor: result.targetBalanceMinor.toString(), deltaMinor: result.deltaMinor.toString(),
    transaction: result.transaction ? response(result.transaction) : null };
}
@Injectable()
export class TransactionService {
  constructor(
    @Inject(TRANSACTION_REPOSITORY) private readonly repository: TransactionRepository,
    private readonly rates: FxRateService,
  ) {}
  async create(userId: string, dto: CreateTransactionDto) {
    const result = await this.repository.create(userId, { type: dto.type, occurredOn: calendarDate(dto.occurredOn),
      occurredTime: occurredTime(dto.occurredTime), legs: legs(dto.legs),
      categoryId: dto.categoryId ?? null, notes: dto.notes ?? null, merchant: dto.merchant ?? null,
      tagIds: tags(dto.tagIds ?? []), fx: fx(dto.fx ?? null) });
    return { transaction: response(result.transaction), created: result.created };
  }
  /** Detail adds each leg in the profile currency (BE-P2-013); stored legs are untouched. */
  async find(userId: string, id: string) {
    const bundle = response(await this.repository.find(userId, id));
    const convert = await this.rates.toProfileCurrency(userId);
    return { ...bundle, legs: bundle.legs.map(leg => ({ ...leg, converted: convert(BigInt(leg.amountMinor), leg.currencyCode) })) };
  }
  async findByClientId(userId: string, clientId: string) {
    const bundle = await this.repository.findByClientId(userId, clientId);
    return bundle ? response(bundle) : null;
  }
  recentMatches(userId: string, query: RecentMatchQuery) { return this.repository.findRecentMatches(userId, query); }
  async list(userId: string, query: TransactionQueryDto) {
    if (query.from) calendarDate(query.from);
    if (query.to) calendarDate(query.to);
    if (query.from && query.to && query.from > query.to) throw new TransactionError('VALIDATION_ERROR');
    const { accountId, categoryId, tagId, ...rest } = query;
    const result = await this.repository.list(userId, { ...rest, accountIds: accountId, categoryIds: categoryId, tagIds: tagId });
    return {
      items: result.items.map(legResponse), total: result.total, page: query.page, pageSize: query.pageSize,
      summary: {
        count: result.summary.count,
        totals: result.summary.totals.map(row => ({
          currency: row.currency, incomeMinor: row.incomeMinor.toString(), expenseMinor: row.expenseMinor.toString(),
          transferInMinor: row.transferInMinor.toString(), transferOutMinor: row.transferOutMinor.toString(), adjustmentMinor: row.adjustmentMinor.toString(), debtMinor: row.debtMinor.toString(), refundMinor: row.refundMinor.toString(),
        })),
      },
    };
  }
  /** BE-P3-010: CSV text (UTF-8 BOM) of the filtered, non-deleted transactions. */
  async exportCsv(userId: string, query: TransactionCsvQueryDto) {
    if (query.from) calendarDate(query.from);
    if (query.to) calendarDate(query.to);
    if (query.from && query.to && query.from > query.to) throw new TransactionError('VALIDATION_ERROR');
    const { accountId, categoryId, tagId, ...rest } = query;
    const rows = await this.repository.listForCsv(userId, { ...rest, page: 1, pageSize: 1, status: 'active', accountIds: accountId, categoryIds: categoryId, tagIds: tagId }, CSV_EXPORT_MAX_ROWS);
    return buildTransactionsCsv(rows);
  }
  async update(userId: string, id: string, dto: UpdateTransactionDto) {
    const { occurredOn, occurredTime: inputTime, legs: inputLegs, fx: inputFx, tagIds, ...rest } = dto;
    const patch: TransactionPatch = { version: dto.version };
    if (rest.categoryId !== undefined) patch.categoryId = rest.categoryId;
    if (rest.notes !== undefined) patch.notes = rest.notes;
    if (rest.merchant !== undefined) patch.merchant = rest.merchant;
    if (rest.deleted !== undefined) patch.deleted = rest.deleted;
    if (rest.refunds !== undefined) patch.refunds = rest.refunds;
    if (occurredOn !== undefined) patch.occurredOn = calendarDate(occurredOn);
    if (inputTime !== undefined) patch.occurredTime = occurredTime(inputTime);
    if (inputLegs !== undefined) patch.legs = legs(inputLegs);
    if (inputFx !== undefined) patch.fx = fx(inputFx);
    if (tagIds !== undefined) patch.tagIds = tags(tagIds);
    return response(await this.repository.update(userId, id, patch));
  }
  async reconcile(userId: string, accountId: string, dto: ReconcileDto) {
    const result = await this.repository.reconcile(userId, accountId, { clientId: dto.clientId, actualBalanceMinor: minor(dto.actualBalanceMinor),
      occurredOn: dto.occurredOn ?? null, notes: dto.notes ?? null, dryRun: dto.dryRun ?? false });
    return { result: reconcileResponse(result), created: result.created };
  }
  async refund(userId: string, originalId: string, dto: RefundDto) {
    const result = await this.repository.refund(userId, originalId, { clientId: dto.clientId, accountId: dto.accountId,
      amountMinor: minor(dto.amountMinor), occurredOn: dto.occurredOn ?? null, notes: dto.notes ?? null });
    return { transaction: response(result.transaction), created: result.created };
  }
  async delete(userId: string, id: string, version: number, refunds?: RefundDisposition): Promise<void> {
    await this.repository.update(userId, id, { version, deleted: true, ...(refunds ? { refunds } : {}) });
  }
}
