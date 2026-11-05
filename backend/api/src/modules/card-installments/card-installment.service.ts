import { Inject, Injectable } from '@nestjs/common';
import { minor } from '../transactions/domain/transaction';
import {
  buildSchedule, CardInstallmentError, dueForRange, remainingPeriods, type CardInstallmentRecord,
} from './domain/card-installment';
import {
  CARD_INSTALLMENT_REPOSITORY, type CardInstallmentRepository,
} from './domain/card-installment.repository';
import type {
  CardInstallmentDueDto, CreateCardInstallmentDto, ListCardInstallmentsDto, PreviewCardInstallmentDto,
} from './card-installment.dto';

const text = (value: bigint) => value.toString();

function summary(plan: CardInstallmentRecord, today: string) {
  const next = remainingPeriods(plan, today)[0] ?? null;
  return {
    id: plan.id,
    clientId: plan.clientId,
    transactionId: plan.transactionId,
    accountId: plan.accountId,
    currencyCode: plan.currencyCode,
    totalMinor: text(plan.totalMinor),
    installmentMinor: text(plan.installmentMinor),
    installmentCount: plan.installmentCount,
    firstDueOn: plan.firstDueOn,
    status: plan.status,
    remainingCount: remainingPeriods(plan, today).length,
    nextDueOn: next?.dueOn ?? null,
    nextAmountMinor: next ? text(next.amountMinor) : null,
    closedAt: plan.closedAt?.toISOString() ?? null,
    version: plan.version,
    createdAt: plan.createdAt.toISOString(),
    updatedAt: plan.updatedAt.toISOString(),
    purchaseOn: plan.purchase?.occurredOn ?? null,
    purchaseMerchant: plan.purchase?.merchant ?? null,
    purchaseNote: plan.purchase?.notes ?? null,
    purchaseCategoryId: plan.purchase?.categoryId ?? null,
  };
}

function detail(plan: CardInstallmentRecord, today: string) {
  return {
    ...summary(plan, today),
    periods: buildSchedule(plan).map(period => ({
      index: period.index,
      dueOn: period.dueOn,
      amountMinor: text(period.amountMinor),
      // A closed plan keeps its history but nothing is still due.
      state: plan.status === 'closed' ? 'closed' : period.dueOn < today ? 'past' : 'upcoming',
    })),
  };
}

@Injectable()
export class CardInstallmentService {
  constructor(@Inject(CARD_INSTALLMENT_REPOSITORY) private readonly repository: CardInstallmentRepository) {}

  async list(userId: string, query: ListCardInstallmentsDto) {
    const [plans, today] = await Promise.all([this.repository.list(userId, query), this.repository.today(userId)]);
    return { items: plans.map(plan => summary(plan, today)) };
  }

  async find(userId: string, id: string) {
    const [plan, today] = await Promise.all([this.repository.find(userId, id), this.repository.today(userId)]);
    return detail(plan, today);
  }

  async create(userId: string, dto: CreateCardInstallmentDto) {
    const result = await this.repository.create(userId, {
      clientId: dto.clientId,
      transactionId: dto.transactionId,
      installmentCount: dto.installmentCount,
      installmentMinor: dto.installmentMinor ? minor(dto.installmentMinor) : null,
      firstDueOn: dto.firstDueOn,
    });
    return { plan: detail(result.plan, await this.repository.today(userId)), created: result.created };
  }

  /** The schedule a create with the same input would make; nothing is written. */
  async preview(userId: string, dto: PreviewCardInstallmentDto) {
    const plan = await this.repository.preview(userId, {
      transactionId: dto.transactionId,
      installmentCount: dto.installmentCount,
      installmentMinor: dto.installmentMinor ? minor(dto.installmentMinor) : null,
      firstDueOn: dto.firstDueOn,
    });
    const periods = buildSchedule(plan);
    return {
      transactionId: plan.transactionId,
      accountId: plan.accountId,
      currencyCode: plan.currencyCode,
      totalMinor: text(plan.totalMinor),
      installmentMinor: text(plan.installmentMinor),
      installmentCount: plan.installmentCount,
      firstDueOn: plan.firstDueOn,
      lastDueOn: periods[periods.length - 1].dueOn,
      periods: periods.map(period => ({ index: period.index, dueOn: period.dueOn, amountMinor: text(period.amountMinor) })),
    };
  }

  async close(userId: string, id: string, version: number) {
    const plan = await this.repository.close(userId, id, version);
    return detail(plan, await this.repository.today(userId));
  }

  /** Instalments falling due in the range, per card, for "số phải trả kỳ này". */
  async due(userId: string, query: CardInstallmentDueDto) {
    if (query.to < query.from) throw new CardInstallmentError('VALIDATION_ERROR');
    const plans = await this.repository.list(userId, { accountId: query.accountId, status: 'active' });
    return {
      from: query.from,
      to: query.to,
      items: dueForRange(plans, query.from, query.to).map(row => ({
        accountId: row.accountId,
        currencyCode: row.currencyCode,
        dueMinor: text(row.dueMinor),
        planCount: row.planCount,
      })),
    };
  }
}
