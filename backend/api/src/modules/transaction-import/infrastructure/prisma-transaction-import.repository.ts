import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { touchFinancialOwner } from '../../../infrastructure/prisma/financial-owner-lock';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import { createTransactionInTx } from '../../transactions/infrastructure/create-transaction-in-tx';
import { TransactionError } from '../../transactions/domain/transaction';
import { TransactionImportError, type RowError } from '../domain/transaction-import';
import type {
  CommitInput, CommitOutcome, ImportBatchRecord, ImportContext, TransactionImportRepository, UndoSkip,
} from '../domain/transaction-import.repository';

const toDate = (value: string) => new Date(`${value}T00:00:00.000Z`);
const audit = (userId: string, batchId: string, action: 'transaction_import.create' | 'transaction_import.undo') => ({
  actorType: 'user' as const, actorId: userId, action, targetType: 'import_batch', targetId: batchId, outcome: 'success' as const,
});
const rowError = (code: TransactionError['code']): RowError =>
  code === 'CATEGORY_KIND_MISMATCH' || code === 'ACCOUNT_NOT_FOUND' || code === 'TRANSACTION_CONFLICT' ? code : 'VALIDATION_ERROR';

type BatchRow = Prisma.ImportBatchGetPayload<Record<string, never>>;
const map = (row: BatchRow, remainingCount: number): ImportBatchRecord => ({
  id: row.id, clientId: row.clientId, preset: row.preset, rowCount: row.rowCount, createdCount: row.createdCount,
  duplicateCount: row.duplicateCount, invalidCount: row.invalidCount, remainingCount, undoneAt: row.undoneAt, createdAt: row.createdAt,
});

@Injectable()
export class PrismaTransactionImportRepository implements TransactionImportRepository {
  constructor(private readonly prisma: PrismaService) {}

  private async write<T>(userId: string, operation: (tx: Prisma.TransactionClient) => Promise<T>): Promise<T> {
    for (let attempt = 0; ; attempt++) {
      try {
        return await this.prisma.$transaction(async tx => {
          await touchFinancialOwner(tx, userId);
          return operation(tx);
        }, { isolationLevel: Prisma.TransactionIsolationLevel.RepeatableRead, timeout: 120_000, maxWait: 10_000 });
      } catch (error) {
        if (
          attempt < 3 &&
          error instanceof Prisma.PrismaClientKnownRequestError &&
          (error.code === 'P2034' || error.code === 'P2002' ||
            (error.code === 'P2010' && ['40001', '40P01'].includes(String(error.meta?.code))))
        ) continue;
        if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') throw new TransactionImportError('IMPORT_CONFLICT');
        throw error;
      }
    }
  }

  async context(userId: string, range: { from: string; to: string } | null): Promise<ImportContext> {
    const [accounts, categories, existing] = await Promise.all([
      this.prisma.financialAccount.findMany({ where: { userId, archivedAt: null }, include: { currency: true }, orderBy: [{ createdAt: 'asc' }, { id: 'asc' }] }),
      this.prisma.category.findMany({ where: { userId, archivedAt: null }, orderBy: [{ createdAt: 'asc' }, { id: 'asc' }] }),
      range
        ? this.prisma.transaction.findMany({
          where: { userId, deletedAt: null, type: { in: ['income', 'expense', 'transfer'] }, occurredOn: { gte: toDate(range.from), lte: toDate(range.to) } },
          select: { id: true, accountId: true, occurredOn: true, amountMinor: true, type: true, merchant: true, notes: true },
        })
        : Promise.resolve([]),
    ]);
    return {
      accounts: accounts.map(row => ({ id: row.id, name: row.name, currencyCode: row.currencyCode.trim(), minorDigits: row.currency.minorDigits })),
      categories: categories.map(row => ({ id: row.id, name: row.name, kind: row.kind })),
      existing: existing.map(row => ({ ...row, occurredOn: row.occurredOn.toISOString().slice(0, 10) })),
    };
  }

  private async remaining(tx: Prisma.TransactionClient, userId: string, batchId: string): Promise<number> {
    return tx.transaction.count({ where: { userId, importBatchId: batchId, deletedAt: null } });
  }

  commit(userId: string, input: CommitInput) {
    return this.write(userId, async tx => {
      const existing = await tx.importBatch.findUnique({ where: { userId_clientId: { userId, clientId: input.clientId } } });
      if (existing) return { batch: map(existing, await this.remaining(tx, userId, existing.id)), outcomes: null, created: false };
      const batch = await tx.importBatch.create({
        data: { userId, clientId: input.clientId, preset: input.preset, rowCount: input.rowCount, createdCount: 0, duplicateCount: 0, invalidCount: 0 },
      });
      const outcomes: CommitOutcome[] = [];
      const clientIds: string[] = [];
      for (const row of input.rows) {
        try {
          await createTransactionInTx(tx, userId, row.input);
          clientIds.push(...row.input.legs.map(leg => leg.clientId));
          outcomes.push({ rows: row.rows, status: 'created' });
        } catch (error) {
          // Domain checks run before any write for the row, so the surrounding transaction stays usable.
          if (!(error instanceof TransactionError)) throw error;
          outcomes.push({ rows: row.rows, status: 'invalid', error: rowError(error.code) });
        }
      }
      await tx.transaction.updateMany({ where: { userId, clientId: { in: clientIds } }, data: { importBatchId: batch.id } });
      const created = outcomes.filter(item => item.status === 'created').length;
      const updated = await tx.importBatch.update({
        where: { id: batch.id },
        data: { createdCount: created, duplicateCount: input.skippedDuplicates, invalidCount: input.plannedInvalid + outcomes.length - created },
      });
      await tx.auditEvent.create({ data: audit(userId, batch.id, 'transaction_import.create') });
      return { batch: map(updated, await this.remaining(tx, userId, batch.id)), outcomes, created: true };
    });
  }

  async find(userId: string, id: string): Promise<ImportBatchRecord> {
    const row = await this.prisma.importBatch.findFirst({ where: { id, userId } });
    if (!row) throw new TransactionImportError('IMPORT_NOT_FOUND');
    return map(row, await this.remaining(this.prisma, userId, id));
  }

  undo(userId: string, id: string) {
    return this.write(userId, async tx => {
      const batch = await tx.importBatch.findFirst({ where: { id, userId } });
      if (!batch) throw new TransactionImportError('IMPORT_NOT_FOUND');
      const rows = await tx.transaction.findMany({
        where: { userId, importBatchId: id, deletedAt: null },
        select: { id: true, version: true, transferGroupId: true, refunds: { where: { deletedAt: null }, select: { id: true } }, installmentPlan: { select: { status: true } } },
        orderBy: { id: 'asc' },
      });
      const groups = new Map<string, typeof rows>();
      for (const row of rows) groups.set(row.transferGroupId ?? row.id, [...(groups.get(row.transferGroupId ?? row.id) ?? []), row]);
      const skipped: UndoSkip[] = [];
      const deletable: string[] = [];
      for (const group of groups.values()) {
        const reason = group.some(row => row.version > 1) ? 'modified'
          : group.some(row => row.refunds.length || row.installmentPlan?.status === 'active') ? 'linked' : null;
        if (reason) skipped.push({ transactionId: group[0].id, reason });
        else deletable.push(...group.map(row => row.id));
      }
      if (deletable.length) await tx.transaction.updateMany({ where: { userId, id: { in: deletable } }, data: { deletedAt: new Date(), version: { increment: 1 } } });
      const updated = await tx.importBatch.update({ where: { id }, data: { undoneAt: batch.undoneAt ?? new Date() } });
      await tx.auditEvent.create({ data: audit(userId, id, 'transaction_import.undo') });
      return { batch: map(updated, await this.remaining(tx, userId, id)), undone: groups.size - skipped.length, skipped };
    });
  }
}
