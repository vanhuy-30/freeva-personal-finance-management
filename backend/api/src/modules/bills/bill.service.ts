import { Inject, Injectable } from '@nestjs/common';
import { BILL_REPOSITORY, type BillRepository } from './domain/bill.repository';
import {
  billFlags,
  dayString,
  normalizeName,
  parseDay,
  positiveMinor,
  type Bill,
} from './domain/bill';
import type {
  CreateBillDto,
  BillQueryDto,
  PayBillDto,
  UnpayBillDto,
  UpdateBillDto,
} from './bill.dto';

function response(bill: Bill, today: string) {
  const flags = billFlags(bill, today);
  return {
    id: bill.id,
    clientId: bill.clientId,
    name: bill.name,
    dueOn: dayString(bill.dueOn),
    amountMinor: bill.amountMinor.toString(),
    amountKind: bill.amountKind,
    currencyCode: bill.currencyCode,
    recurringRuleId: bill.recurringRuleId,
    paidTransactionId: bill.paidTransactionId,
    paid: flags.paid,
    overdue: flags.overdue,
    version: bill.version,
    createdAt: bill.createdAt.toISOString(),
    updatedAt: bill.updatedAt.toISOString(),
  };
}

@Injectable()
export class BillService {
  constructor(@Inject(BILL_REPOSITORY) private readonly repository: BillRepository) {}

  async create(userId: string, dto: CreateBillDto) {
    const result = await this.repository.create(userId, {
      clientId: dto.clientId,
      name: normalizeName(dto.name),
      dueOn: parseDay(dto.dueOn),
      amountMinor: positiveMinor(dto.amountMinor),
      amountKind: dto.amountKind,
      currencyCode: dto.currencyCode,
      recurringRuleId: dto.recurringRuleId === undefined ? null : dto.recurringRuleId,
    });
    const today = await this.repository.todayForUser(userId);
    return { bill: response(result.bill, today), created: result.created };
  }

  async find(userId: string, id: string) {
    const bill = await this.repository.find(userId, id);
    const today = await this.repository.todayForUser(userId);
    return response(bill, today);
  }

  async list(userId: string, query: BillQueryDto) {
    const result = await this.repository.list(userId, query);
    return {
      items: result.items.map(bill => response(bill, result.today)),
      total: result.total,
      page: query.page,
      pageSize: query.pageSize,
    };
  }

  async update(userId: string, id: string, dto: UpdateBillDto) {
    const { version, name, dueOn, amountMinor, ...rest } = dto;
    const bill = await this.repository.update(userId, id, {
      version,
      ...rest,
      ...(name !== undefined ? { name: normalizeName(name) } : {}),
      ...(dueOn !== undefined ? { dueOn: parseDay(dueOn) } : {}),
      ...(amountMinor !== undefined ? { amountMinor: positiveMinor(amountMinor) } : {}),
    });
    const today = await this.repository.todayForUser(userId);
    return response(bill, today);
  }

  delete(userId: string, id: string, version: number) {
    return this.repository.delete(userId, id, version);
  }

  async pay(userId: string, id: string, dto: PayBillDto) {
    const bill = await this.repository.pay(userId, id, dto.transactionId, dto.version);
    const today = await this.repository.todayForUser(userId);
    return response(bill, today);
  }

  async unpay(userId: string, id: string, dto: UnpayBillDto) {
    const bill = await this.repository.unpay(userId, id, dto.version);
    const today = await this.repository.todayForUser(userId);
    return response(bill, today);
  }
}
