import { Inject, Injectable } from '@nestjs/common';
import { minor, normalizeRate } from '../transactions/domain/transaction';
import { RECURRING_REPOSITORY, type RecurringRepository } from './domain/recurring.repository';
import { dayString, parseDay, remindFlags, RecurringError, type RecurringRule } from './domain/recurring';
import type { ConfirmRecurringDto, CreateRecurringDto, RecurringQueryDto, UpdateRecurringDto } from './recurring.dto';

function response(rule: RecurringRule, today: string) {
  const flags = remindFlags(rule, today);
  return {
    id: rule.id,
    clientId: rule.clientId,
    type: rule.type,
    mode: rule.mode,
    name: rule.name,
    amountKind: rule.amountKind,
    remindDaysBefore: rule.remindDaysBefore,
    overdue: flags.overdue,
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
    const mode = dto.mode ?? 'auto';
    const startDate = parseDay(dto.startDate);
    const result = await this.repository.create(userId, {
      clientId: dto.clientId,
      type: dto.type,
      mode,
      name: dto.name == null ? null : dto.name.trim(),
      amountKind: dto.amountKind ?? 'fixed',
      remindDaysBefore: dto.remindDaysBefore ?? 3,
      unit: dto.unit,
      interval: dto.interval,
      amountMinor: minor(dto.amountMinor),
      currencyCode: dto.currencyCode,
      accountId: dto.accountId ?? null,
      categoryId: dto.categoryId === undefined ? null : dto.categoryId,
      counterAccountId: dto.counterAccountId === undefined ? null : dto.counterAccountId,
      counterAmountMinor: dto.counterAmountMinor == null ? null : minor(dto.counterAmountMinor),
      counterCurrencyCode: dto.counterCurrencyCode === undefined ? null : dto.counterCurrencyCode,
      fxRate: dto.fxRate == null ? null : normalizeRate(dto.fxRate),
      startDate,
      endDate: dto.repeat === false ? startDate : dto.endDate == null ? null : parseDay(dto.endDate),
      nextExecutionDate: parseDay(dto.nextExecutionDate),
      active: dto.active ?? true,
    });
    return { rule: response(result.rule, await this.repository.todayForUser(userId)), created: result.created };
  }

  async find(userId: string, id: string) {
    const rule = await this.repository.find(userId, id);
    return response(rule, await this.repository.todayForUser(userId));
  }

  async list(userId: string, query: RecurringQueryDto) {
    const result = await this.repository.list(userId, query);
    const today = await this.repository.todayForUser(userId);
    return {
      items: result.items.map(rule => response(rule, today)),
      total: result.total,
      page: query.page,
      pageSize: query.pageSize,
    };
  }

  async update(userId: string, id: string, dto: UpdateRecurringDto) {
    const {
      version, amountMinor, counterAmountMinor, fxRate, startDate, endDate, nextExecutionDate, ...rest
    } = dto;
    const updated = await this.repository.update(userId, id, {
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
    });
    return response(updated, await this.repository.todayForUser(userId));
  }

  async confirm(userId: string, id: string, dto: ConfirmRecurringDto) {
    if (dto.transactionId !== undefined && (dto.accountId !== undefined || dto.amountMinor !== undefined)) {
      throw new RecurringError('VALIDATION_ERROR');
    }
    const result = await this.repository.confirm(userId, id, {
      version: dto.version,
      occurredOn: parseDay(dto.occurredOn),
      transactionId: dto.transactionId ?? null,
      accountId: dto.accountId ?? null,
      categoryId: dto.categoryId ?? null,
      amountMinor: dto.amountMinor === undefined ? null : minor(dto.amountMinor),
      paidOn: dto.paidOn === undefined ? null : parseDay(dto.paidOn),
    });
    return {
      rule: response(result.rule, await this.repository.todayForUser(userId)),
      transactionId: result.transactionId,
      replayed: result.replayed,
    };
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
