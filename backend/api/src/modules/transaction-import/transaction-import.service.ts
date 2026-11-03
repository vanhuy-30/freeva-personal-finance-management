import { Inject, Injectable } from '@nestjs/common';
import { calendarDate, type TransactionInput } from '../transactions/domain/transaction';
import { CsvParseError, detectDelimiter, parseCsv } from './domain/csv-parse';
import { detectPreset, formatFor, IMPORT_FIELDS, type ImportPreset } from './domain/import-format';
import {
  deterministicUuid, parseRows, planRows, TransactionImportError, type ParsedRow, type PlannedRow, type RowError,
} from './domain/transaction-import';
import {
  TRANSACTION_IMPORT_REPOSITORY, type ImportBatchRecord, type TransactionImportRepository,
} from './domain/transaction-import.repository';
import type { CommitImportDto, PreviewImportDto } from './transaction-import.dto';

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;

function maps(dto: PreviewImportDto) {
  const walletMap = dto.walletMap ?? {};
  const categoryMap = dto.categoryMap ?? {};
  const wallets = Object.entries(walletMap);
  const categories = Object.entries(categoryMap);
  if (wallets.length > 500 || categories.length > 500 ||
    wallets.some(([name, id]) => name.length > 200 || typeof id !== 'string' || !UUID.test(id)) ||
    categories.some(([name, id]) => name.length > 200 || (id !== null && (typeof id !== 'string' || !UUID.test(id))))) {
    throw new TransactionImportError('VALIDATION_ERROR');
  }
  return { walletMap, categoryMap, defaultAccountId: dto.defaultAccountId ?? null };
}

function batch(record: ImportBatchRecord) {
  return {
    id: record.id, clientId: record.clientId, preset: record.preset, rowCount: record.rowCount, createdCount: record.createdCount,
    duplicateCount: record.duplicateCount, invalidCount: record.invalidCount, remainingCount: record.remainingCount,
    undoneAt: record.undoneAt?.toISOString() ?? null, createdAt: record.createdAt.toISOString(),
  };
}

const rowView = (row: PlannedRow) => ({
  rows: row.rows, status: row.status, errors: row.errors, type: row.type, occurredOn: row.occurredOn, occurredTime: row.occurredTime,
  accountId: row.legs[0]?.accountId ?? null, toAccountId: row.legs[1]?.accountId ?? null, currencyCode: row.legs[0]?.currencyCode ?? null,
  amountMinor: row.legs[0] ? (row.legs[0].amountMinor < 0n ? -row.legs[0].amountMinor : row.legs[0].amountMinor).toString() : null,
  categoryId: row.categoryId, merchant: row.merchant, notes: row.notes, duplicateOfId: row.duplicateOf,
});

@Injectable()
export class TransactionImportService {
  constructor(@Inject(TRANSACTION_IMPORT_REPOSITORY) private readonly repository: TransactionImportRepository) {}

  private async prepare(userId: string, dto: PreviewImportDto) {
    let table: string[][];
    try { table = parseCsv(dto.text, detectDelimiter(dto.text)); } catch (error) {
      if (error instanceof CsvParseError) throw new TransactionImportError('FILE_INVALID');
      throw error;
    }
    if (!table.length) throw new TransactionImportError('FILE_INVALID');
    const preset: ImportPreset = dto.preset ?? detectPreset(table[0]);
    const format = formatFor(preset, { dateFormat: dto.dateFormat, numberFormat: dto.numberFormat, mapping: dto.mapping });
    const { rows, columns } = parseRows(table, format);
    const dates = rows.flatMap(row => (row.date ? [row.date] : [])).sort();
    const context = await this.repository.context(userId, dates.length ? { from: dates[0], to: dates[dates.length - 1] } : null);
    const selected = maps(dto);
    const planned = planRows(rows, selected, context.accounts, context.categories, context.existing);
    return { preset, table, rows, columns, planned };
  }

  async preview(userId: string, dto: PreviewImportDto) {
    const { preset, table, rows, columns, planned } = await this.prepare(userId, dto);
    const unmapped = (error: RowError, pick: (row: ParsedRow) => string) => [...new Set(planned
      .filter(item => item.errors.includes(error))
      .flatMap(item => item.rows.map(index => rows[index - 1]))
      .map(pick))];
    return {
      preset,
      columns: Object.fromEntries(IMPORT_FIELDS.flatMap(field => (columns[field] === undefined ? [] : [[field, table[0][columns[field]!]]]))),
      summary: {
        rowCount: rows.length,
        ready: planned.filter(item => item.status === 'ready').length,
        duplicate: planned.filter(item => item.status === 'duplicate').length,
        invalid: planned.filter(item => item.status === 'invalid').length,
      },
      unmapped: { wallets: unmapped('WALLET_UNMAPPED', row => row.wallet), categories: unmapped('CATEGORY_UNMAPPED', row => row.category) },
      rows: planned.map(rowView),
    };
  }

  async commit(userId: string, dto: CommitImportDto) {
    const { preset, rows, planned } = await this.prepare(userId, dto);
    const include = dto.includeDuplicates === true;
    const writable = planned.filter(item => item.status === 'ready' || (include && item.status === 'duplicate'));
    const result = await this.repository.commit(userId, {
      clientId: dto.batchClientId, preset, rowCount: rows.length,
      skippedDuplicates: include ? 0 : planned.filter(item => item.status === 'duplicate').length,
      plannedInvalid: planned.filter(item => item.status === 'invalid').length,
      rows: writable.map(item => ({
        rows: item.rows,
        input: {
          type: item.type!, occurredOn: calendarDate(item.occurredOn!), occurredTime: item.occurredTime,
          legs: item.legs.map((leg, index) => ({ ...leg, clientId: deterministicUuid(dto.batchClientId, item.rows[0], index) })),
          categoryId: item.categoryId, notes: item.notes, merchant: item.merchant, tagIds: [], fx: null,
        } satisfies TransactionInput,
      })),
    });
    const failed = new Map((result.outcomes ?? []).flatMap(item => (item.status === 'invalid' ? [[item.rows[0], item.error] as const] : [])));
    return {
      created: result.created,
      batch: batch(result.batch),
      // A replay returns only the stored counts: the per-row outcome was already delivered with the first response.
      rows: result.outcomes === null ? null : planned.map(item => {
        const error = failed.get(item.rows[0]);
        const status = item.status === 'invalid' || error ? 'invalid' : item.status === 'duplicate' && !include ? 'skipped_duplicate' : 'created';
        return { ...rowView(item), status, errors: error ? [error] : item.errors };
      }),
    };
  }

  async find(userId: string, id: string) {
    return batch(await this.repository.find(userId, id));
  }

  async undo(userId: string, id: string) {
    const result = await this.repository.undo(userId, id);
    return { batch: batch(result.batch), undoneCount: result.undone, skipped: result.skipped };
  }
}
