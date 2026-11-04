import { Inject, Injectable } from '@nestjs/common';
import { minor } from '../transactions/domain/transaction';
import {
  dueInMonth,
  loanStatus,
  paidMinor,
  percentBps,
  periodInterest,
  schedule,
  scheduleDueDates,
  totalInterest,
  LoanError,
  type LoanRecord,
} from './domain/loan';
import { LOAN_REPOSITORY, type LoanContext, type LoanRepository } from './domain/loan.repository';
import type { AdjustLoanDto, CreateLoanDto, PayLoanDto, UpdateLoanDto } from './loan.dto';

const text = (value: bigint) => value.toString();
const orNull = (value: bigint | null) => (value === null ? null : text(value));

function plan(loan: LoanRecord) {
  if (loan.installmentMinor === null || loan.installmentMinor <= 0n || loan.outstandingMinor <= 0n) return null;
  return schedule(loan.outstandingMinor, loan.interestRateBps, loan.frequency, loan.installmentMinor);
}

function response(loan: LoanRecord, context: LoanContext) {
  const rows = plan(loan);
  return {
    id: loan.id,
    clientId: loan.clientId,
    kind: loan.kind,
    name: loan.name,
    currencyCode: loan.currencyCode,
    principalMinor: text(loan.principalMinor),
    outstandingMinor: text(loan.outstandingMinor),
    paidMinor: text(paidMinor(loan.principalMinor, loan.outstandingMinor)),
    percentBps: percentBps(loan.principalMinor, loan.outstandingMinor),
    interestRateBps: loan.interestRateBps,
    installmentMinor: orNull(loan.installmentMinor),
    frequency: loan.frequency,
    startDate: loan.startDate,
    endDate: loan.endDate,
    nextDueDate: loan.nextDueDate,
    periodInterestMinor: text(periodInterest(loan.outstandingMinor, loan.interestRateBps, loan.frequency)),
    remainingPeriods: rows === null ? null : rows.length,
    expectedInterestMinor: orNull(totalInterest(rows)),
    status: loanStatus(loan.outstandingMinor, loan.nextDueDate, context.today),
    accountId: loan.accountId,
    archivedAt: loan.archivedAt?.toISOString() ?? null,
    version: loan.version,
    createdAt: loan.createdAt.toISOString(),
    updatedAt: loan.updatedAt.toISOString(),
  };
}

@Injectable()
export class LoanService {
  constructor(@Inject(LOAN_REPOSITORY) private readonly repository: LoanRepository) {}

  async list(userId: string, includeArchived = false) {
    const [loans, context] = await Promise.all([this.repository.list(userId, includeArchived), this.repository.context(userId)]);
    return { items: loans.map(loan => response(loan, context)) };
  }

  async find(userId: string, id: string) {
    const [loan, context] = await Promise.all([this.repository.find(userId, id), this.repository.context(userId)]);
    return response(loan, context);
  }

  /** Totals per currency over active loans: borrowed, paid, still owed, and expected interest on the plans that amortize. */
  async summary(userId: string) {
    const [loans, context] = await Promise.all([this.repository.list(userId, false), this.repository.context(userId)]);
    const totals = new Map<string, { principal: bigint; paid: bigint; outstanding: bigint; interest: bigint; due: bigint; count: number }>();
    for (const loan of loans) {
      const entry = totals.get(loan.currencyCode) ?? { principal: 0n, paid: 0n, outstanding: 0n, interest: 0n, due: 0n, count: 0 };
      const rows = plan(loan);
      entry.principal += loan.principalMinor;
      entry.paid += paidMinor(loan.principalMinor, loan.outstandingMinor);
      entry.outstanding += loan.outstandingMinor;
      entry.interest += totalInterest(rows) ?? 0n;
      entry.due += dueInMonth(rows, loan.nextDueDate, loan.frequency, context.today);
      entry.count += 1;
      totals.set(loan.currencyCode, entry);
    }
    return {
      items: [...totals.entries()].sort(([a], [b]) => a.localeCompare(b)).map(([currencyCode, entry]) => ({
        currencyCode,
        loanCount: entry.count,
        principalMinor: text(entry.principal),
        paidMinor: text(entry.paid),
        outstandingMinor: text(entry.outstanding),
        expectedInterestMinor: text(entry.interest),
        dueThisMonthMinor: text(entry.due),
      })),
    };
  }

  async schedule(userId: string, id: string) {
    const loan = await this.repository.find(userId, id);
    const rows = plan(loan);
    const dates = scheduleDueDates(loan.nextDueDate, loan.frequency, rows?.length ?? 0);
    return {
      loanId: loan.id,
      currencyCode: loan.currencyCode,
      assumption: { outstandingMinor: text(loan.outstandingMinor), interestRateBps: loan.interestRateBps, frequency: loan.frequency, installmentMinor: orNull(loan.installmentMinor) },
      items: (rows ?? []).map((row, i) => ({
        index: row.index,
        dueDate: dates[i] ?? null,
        interestMinor: text(row.interestMinor),
        principalMinor: text(row.principalMinor),
        paymentMinor: text(row.paymentMinor),
        outstandingAfterMinor: text(row.outstandingAfterMinor),
      })),
      expectedInterestMinor: orNull(totalInterest(rows)),
    };
  }

  async payments(userId: string, id: string) {
    const items = await this.repository.payments(userId, id);
    return {
      items: items.map(item => ({
        id: item.id,
        clientId: item.clientId,
        principalMinor: text(item.principalMinor),
        interestMinor: text(item.interestMinor),
        totalMinor: text(item.principalMinor + item.interestMinor),
        paidOn: item.paidOn,
        createdAt: item.createdAt.toISOString(),
      })),
    };
  }

  async create(userId: string, dto: CreateLoanDto) {
    const principal = minor(dto.principalMinor);
    const result = await this.repository.create(userId, {
      clientId: dto.clientId,
      kind: dto.kind,
      name: dto.name,
      currencyCode: dto.currencyCode,
      principalMinor: principal,
      outstandingMinor: dto.outstandingMinor === undefined ? principal : minor(dto.outstandingMinor),
      interestRateBps: dto.interestRateBps,
      installmentMinor: dto.installmentMinor == null ? null : minor(dto.installmentMinor),
      frequency: dto.frequency,
      startDate: dto.startDate,
      endDate: dto.endDate ?? null,
      nextDueDate: dto.nextDueDate ?? null,
      accountId: dto.accountId ?? null,
    });
    return { loan: response(result.loan, await this.repository.context(userId)), created: result.created };
  }

  async update(userId: string, id: string, dto: UpdateLoanDto) {
    const loan = await this.repository.update(userId, id, {
      version: dto.version,
      kind: dto.kind,
      name: dto.name,
      interestRateBps: dto.interestRateBps,
      installmentMinor: dto.installmentMinor === undefined ? undefined : dto.installmentMinor === null ? null : minor(dto.installmentMinor),
      frequency: dto.frequency,
      endDate: dto.endDate,
      nextDueDate: dto.nextDueDate,
      accountId: dto.accountId,
    });
    return response(loan, await this.repository.context(userId));
  }

  archive(userId: string, id: string, version: number) {
    return this.repository.archive(userId, id, version);
  }

  async pay(userId: string, id: string, dto: PayLoanDto) {
    if ((dto.principalMinor == null) !== (dto.interestMinor == null)) throw new LoanError('VALIDATION_ERROR');
    const result = await this.repository.pay(userId, id, {
      clientId: dto.clientId,
      accountId: dto.accountId ?? null,
      amountMinor: minor(dto.amountMinor),
      principalMinor: dto.principalMinor == null ? null : minor(dto.principalMinor),
      interestMinor: dto.interestMinor == null ? null : minor(dto.interestMinor),
      principalCategoryId: dto.principalCategoryId ?? null,
      interestCategoryId: dto.interestCategoryId ?? null,
      paidOn: dto.paidOn,
    });
    return { loan: response(result.loan, await this.repository.context(userId)), created: result.created };
  }

  async adjust(userId: string, id: string, dto: AdjustLoanDto) {
    const loan = await this.repository.adjust(userId, id, minor(dto.outstandingMinor), dto.version);
    return response(loan, await this.repository.context(userId));
  }
}
