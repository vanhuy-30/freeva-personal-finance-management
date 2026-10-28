import { Inject, Injectable } from '@nestjs/common';
import { minor, normalizeRate } from '../transactions/domain/transaction';
import { RECURRING_REPOSITORY, type RecurringRepository } from './domain/recurring.repository';
import { dayString, parseDay, type RecurringRule } from './domain/recurring';
import type { CreateRecurringDto, RecurringQueryDto, UpdateRecurringDto } from './recurring.dto';

function response(rule: RecurringRule) {
  return {
    id: rule.id,
    clientId: rule.clientId,
    type: rule.type,
    unit: rule.unit,
    interval: rule.interval,
    amountMinor: rule.amountMinor.toString(),
    currencyCode: rule.currencyCode,
    accountId: rule.accountId,
    categoryId: rule.categoryId,
    counterAccountId: rule.counterAccountId,
    counterAmountMinor: rule.counterAmountMinor?.toString() ?? null,
    counterCurrencyCode: rule.counterCurrencyCode,
    fxRate: rule.fxRate,
    startDate: dayString(rule.startDate),
    endDate: rule.endDate ? dayString(rule.endDate) : null,
    nextExecutionDate: dayString(rule.nextExecutionDate),
    active: rule.active,
    version: rule.version,
    createdAt: rule.createdAt.toISOString(),
    updatedAt: rule.updatedAt.toISOString(),
  };
}

@Injectable()
export class RecurringService {
  constructor(@Inject(RECURRING_REPOSITORY) private readonly repository: RecurringRepository) {}

  async create(userId: string, dto: CreateRecurringDto) {
    const result = await this.repository.create(userId, {
      clientId: dto.clientId,
      type: dto.type,
      unit: dto.unit,
      interval: dto.interval,
      amountMinor: minor(dto.amountMinor),
      currencyCode: dto.currencyCode,
      accountId: dto.accountId,
      categoryId: dto.categoryId === undefined ? null : dto.categoryId,
      counterAccountId: dto.counterAccountId === undefined ? null : dto.counterAccountId,
      counterAmountMinor: dto.counterAmountMinor == null ? null : minor(dto.counterAmountMinor),
      counterCurrencyCode: dto.counterCurrencyCode === undefined ? null : dto.counterCurrencyCode,
      fxRate: dto.fxRate == null ? null : normalizeRate(dto.fxRate),
      startDate: parseDay(dto.startDate),
      endDate: dto.endDate == null ? null : parseDay(dto.endDate),
      nextExecutionDate: parseDay(dto.nextExecutionDate),
      active: dto.active ?? true,
    });
    return { rule: response(result.rule), created: result.created };
  }

  async find(userId: string, id: string) {
    return response(await this.repository.find(userId, id));
  }

  async list(userId: string, query: RecurringQueryDto) {
    const result = await this.repository.list(userId, query);
    return {
      items: result.items.map(response),
      total: result.total,
      page: query.page,
      pageSize: query.pageSize,
    };
  }

  async update(userId: string, id: string, dto: UpdateRecurringDto) {
    const {
      version, amountMinor, counterAmountMinor, fxRate, startDate, endDate, nextExecutionDate, ...rest
    } = dto;
    return response(await this.repository.update(userId, id, {
      version,
      ...rest,
      ...(amountMinor !== undefined ? { amountMinor: minor(amountMinor) } : {}),
      ...(counterAmountMinor !== undefined
        ? { counterAmountMinor: counterAmountMinor === null ? null : minor(counterAmountMinor) }
        : {}),
      ...(fxRate !== undefined ? { fxRate: fxRate === null ? null : normalizeRate(fxRate) } : {}),
      ...(startDate !== undefined ? { startDate: parseDay(startDate) } : {}),
      ...(endDate !== undefined ? { endDate: endDate === null ? null : parseDay(endDate) } : {}),
      ...(nextExecutionDate !== undefined ? { nextExecutionDate: parseDay(nextExecutionDate) } : {}),
    }));
  }

  delete(userId: string, id: string, version: number) {
    return this.repository.delete(userId, id, version);
  }

  run(userId: string) {
    return this.repository.runDue(userId);
  }

  runAll() {
    return this.repository.runDue(null);
  }
}
