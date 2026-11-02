import { Inject, Injectable } from '@nestjs/common';
import { minor } from '../transactions/domain/transaction';
import { debtStatus, debtTotals, type PersonalDebtRecord } from './domain/personal-debt';
import {
  PERSONAL_DEBT_REPOSITORY,
  type PersonalDebtContext,
  type PersonalDebtRepository,
} from './domain/personal-debt.repository';
import type { CreatePersonalDebtDto, PayPersonalDebtDto, UpdatePersonalDebtDto } from './personal-debt.dto';

const text = (value: bigint) => value.toString();

function response(debt: PersonalDebtRecord, context: PersonalDebtContext) {
  return {
    id: debt.id,
    clientId: debt.clientId,
    direction: debt.direction,
    counterparty: debt.counterparty,
    currencyCode: debt.currencyCode,
    principalMinor: text(debt.principalMinor),
    outstandingMinor: text(debt.outstandingMinor),
    paidMinor: text(debt.principalMinor - debt.outstandingMinor),
    accountId: debt.accountId,
    occurredOn: debt.occurredOn,
    dueDate: debt.dueDate,
    note: debt.note,
    status: debtStatus(debt.outstandingMinor, debt.dueDate, context.today),
    archivedAt: debt.archivedAt?.toISOString() ?? null,
    version: debt.version,
    createdAt: debt.createdAt.toISOString(),
    updatedAt: debt.updatedAt.toISOString(),
  };
}

@Injectable()
export class PersonalDebtService {
  constructor(@Inject(PERSONAL_DEBT_REPOSITORY) private readonly repository: PersonalDebtRepository) {}

  async list(userId: string, includeArchived = false) {
    const [debts, context] = await Promise.all([this.repository.list(userId, includeArchived), this.repository.context(userId)]);
    return { items: debts.map(debt => response(debt, context)) };
  }

  async find(userId: string, id: string) {
    const [debt, context] = await Promise.all([this.repository.find(userId, id), this.repository.context(userId)]);
    return response(debt, context);
  }

  /** "Ai nợ mình / Mình nợ ai": open debts split by direction, with totals per currency. */
  async summary(userId: string) {
    const [debts, context] = await Promise.all([this.repository.list(userId, false), this.repository.context(userId)]);
    const open = debts.filter(debt => debt.outstandingMinor > 0n);
    return {
      owedToMe: open.filter(debt => debt.direction === 'lent').map(debt => response(debt, context)),
      iOwe: open.filter(debt => debt.direction === 'borrowed').map(debt => response(debt, context)),
      totals: debtTotals(open).map(row => ({
        currencyCode: row.currencyCode,
        receivableMinor: text(row.receivableMinor),
        payableMinor: text(row.payableMinor),
        receivableCount: row.receivableCount,
        payableCount: row.payableCount,
      })),
    };
  }

  async payments(userId: string, id: string) {
    const items = await this.repository.payments(userId, id);
    return {
      items: items.map(item => ({
        id: item.id,
        clientId: item.clientId,
        accountId: item.accountId,
        amountMinor: text(item.amountMinor),
        paidOn: item.paidOn,
        createdAt: item.createdAt.toISOString(),
      })),
    };
  }

  async create(userId: string, dto: CreatePersonalDebtDto) {
    const result = await this.repository.create(userId, {
      clientId: dto.clientId,
      direction: dto.direction,
      counterparty: dto.counterparty,
      amountMinor: minor(dto.amountMinor),
      accountId: dto.accountId,
      occurredOn: dto.occurredOn,
      dueDate: dto.dueDate ?? null,
      note: dto.note ?? null,
    });
    return { debt: response(result.debt, await this.repository.context(userId)), created: result.created };
  }

  async update(userId: string, id: string, dto: UpdatePersonalDebtDto) {
    const debt = await this.repository.update(userId, id, {
      version: dto.version,
      counterparty: dto.counterparty,
      dueDate: dto.dueDate,
      note: dto.note,
    });
    return response(debt, await this.repository.context(userId));
  }

  archive(userId: string, id: string, version: number) {
    return this.repository.archive(userId, id, version);
  }

  async pay(userId: string, id: string, dto: PayPersonalDebtDto) {
    const result = await this.repository.pay(userId, id, {
      clientId: dto.clientId,
      accountId: dto.accountId ?? null,
      amountMinor: minor(dto.amountMinor),
      paidOn: dto.paidOn,
    });
    return { debt: response(result.debt, await this.repository.context(userId)), created: result.created };
  }
}
