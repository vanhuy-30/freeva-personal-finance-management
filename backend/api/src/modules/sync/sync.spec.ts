import 'reflect-metadata';
import { randomUUID } from 'node:crypto';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { TransactionError } from '../transactions/domain/transaction';
import { amountsDiffer, selectDuplicates, type DuplicateCandidate } from './domain/sync';
import { SyncRequestDto } from './sync.dto';
import { SyncService } from './sync.service';

const options = { whitelist: true, forbidNonWhitelisted: true };
const day = new Date('2026-10-09T00:00:00.000Z');
const at = new Date('2026-10-09T03:00:00.000Z');
const clientId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const accountId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const income = (amount = '150000', id = clientId) => ({ type: 'income', occurredOn: '2026-10-09', legs: [{ clientId: id, accountId, currencyCode: 'VND', amountMinor: amount }] });
const createOp = (body = income(), opId = '11111111-1111-4111-8111-111111111111') => ({ opId, action: 'create', body });
const candidate = (patch: Partial<DuplicateCandidate>): DuplicateCandidate => ({
  id: randomUUID(), clientId: randomUUID(), accountId, amountMinor: 150000n, occurredOn: day, createdAt: new Date(at.getTime() - 60_000), deletedAt: null, ...patch,
});
const bundle = (amount = '150000') => ({ legs: [{ id: randomUUID(), clientId, accountId, amountMinor: amount, occurredOn: '2026-10-09', createdAt: at.toISOString() }], fx: null });
describe('BE-P1-009 sync queue', () => {
  it('accepts create, update and delete operations and rejects a malformed queue', async () => {
    const valid = { schemaVersion: 1, operations: [
      createOp(),
      { opId: '22222222-2222-4222-8222-222222222222', action: 'update', id: randomUUID(), body: { version: 1, notes: null } },
      { opId: '33333333-3333-4333-8333-333333333333', action: 'delete', id: randomUUID(), version: 2 },
    ] };
    expect(await validate(plainToInstance(SyncRequestDto, valid), options)).toHaveLength(0);
    expect(plainToInstance(SyncRequestDto, { schemaVersion: 1, operations: [createOp(income('150000', clientId.toUpperCase()), clientId.toUpperCase())] }).operations[0].opId).toBe(clientId);
    for (const request of [
      { schemaVersion: 0, operations: [createOp()] },
      { schemaVersion: 1, operations: [] },
      { schemaVersion: 1, operations: Array.from({ length: 51 }, () => createOp(income(), randomUUID())) },
      { schemaVersion: 1, operations: [createOp(), createOp()] },
      { schemaVersion: 1, operations: [{ ...createOp(), id: randomUUID() }] },
      { schemaVersion: 1, operations: [{ opId: randomUUID(), action: 'delete', id: randomUUID(), version: 1, body: income() }] },
      { schemaVersion: 1, operations: [{ opId: randomUUID(), action: 'update', body: { version: 1 } }] },
      { schemaVersion: 1, operations: [createOp()], userId: randomUUID() },
      { schemaVersion: 1, operations: [{ ...createOp(), body: { ...income(), userId: randomUUID() } }] },
    ]) expect((await validate(plainToInstance(SyncRequestDto, request), options)).length).toBeGreaterThan(0);
  });
  it('suggests the same account, amount and day inside ten minutes, including one transfer leg', () => {
    const created = { clientIds: ['own'], legs: [{ accountId, amountMinor: 150000n }, { accountId: 'dest', amountMinor: -150000n }], occurredOn: day, createdAt: at };
    const matched = candidate({ clientId: 'expense' });
    expect(selectDuplicates(created, [matched])).toEqual([{ id: matched.id, clientId: 'expense' }]);
    expect(selectDuplicates(created, [candidate({ createdAt: new Date(at.getTime() - 10 * 60 * 1000) })])).toHaveLength(1);
    expect(selectDuplicates(created, [candidate({ createdAt: at })])).toHaveLength(1);
    for (const patch of [
      { createdAt: new Date(at.getTime() - 10 * 60 * 1000 - 1) },
      { createdAt: new Date(at.getTime() + 1) },
      { deletedAt: at },
      { accountId: 'other' },
      { amountMinor: -101n },
      { occurredOn: new Date('2026-10-10T00:00:00.000Z') },
      { clientId: 'own' },
    ]) expect(selectDuplicates(created, [candidate(patch)])).toEqual([]);
    const many = Array.from({ length: 6 }, (_, index) => candidate({ id: `${index}`, createdAt: new Date(at.getTime() - index * 1000) }));
    expect(selectDuplicates(created, [...many, many[0]]).map(item => item.id)).toEqual(['5', '4', '3', '2', '1']);
  });
  it('flags review only when a comparable amount differs', () => {
    const server = [{ clientId, amountMinor: -100n }];
    expect(amountsDiffer(undefined, server)).toBe(false);
    expect(amountsDiffer([{ clientId, amountMinor: -100n }], null)).toBe(false);
    expect(amountsDiffer([{ clientId, amountMinor: -100n }], server)).toBe(false);
    expect(amountsDiffer([{ clientId: 'other', amountMinor: -1n }], server)).toBe(false);
    expect(amountsDiffer([{ clientId, amountMinor: -101n }, { clientId: 'other', amountMinor: -100n }], server)).toBe(true);
  });
  it('does not create when the schema does not match and stops after an unexpected failure', async () => {
    const transactions = { create: jest.fn(), update: jest.fn(), delete: jest.fn(), find: jest.fn(), findByClientId: jest.fn(), recentMatches: jest.fn().mockResolvedValue([]) };
    const schemas = { schemaVersion: jest.fn().mockResolvedValue(1) };
    const sync = new SyncService(transactions as never, schemas);
    schemas.schemaVersion.mockResolvedValueOnce(2);
    await expect(sync.apply('user', plainToInstance(SyncRequestDto, { schemaVersion: 1, operations: [createOp()] }))).rejects.toMatchObject({ code: 'SYNC_SCHEMA_MISMATCH' });
    schemas.schemaVersion.mockResolvedValueOnce(null);
    await expect(sync.apply('user', { schemaVersion: 1, operations: [createOp()] } as never)).rejects.toMatchObject({ code: 'SYNC_UNAVAILABLE' });
    await expect(sync.apply('user', { schemaVersion: 1, operations: [createOp(), createOp()] } as never)).rejects.toMatchObject({ code: 'VALIDATION_ERROR' });
    expect(transactions.create).not.toHaveBeenCalled();
    transactions.create.mockResolvedValueOnce({ created: true, transaction: bundle() }).mockRejectedValueOnce(new Error('db 135792468'));
    const stopped = await sync.apply('user', { schemaVersion: 1, operations: [createOp(income(), randomUUID()), createOp(income(), randomUUID()), createOp(income(), randomUUID())] } as never);
    expect(stopped.results.map(result => result.status)).toEqual(['applied', 'rejected']);
    expect(stopped.results[1].error?.code).toBe('TRANSACTIONS_UNAVAILABLE');
    expect(JSON.stringify(stopped)).not.toContain('135792468');
    expect(transactions.create).toHaveBeenCalledTimes(2);
    transactions.create.mockRejectedValueOnce(new TransactionError('TRANSACTION_CONFLICT'));
    transactions.findByClientId.mockResolvedValue(bundle('-100'));
    const conflict = await sync.apply('user', { schemaVersion: 1, operations: [createOp(income('-200'))] } as never);
    expect(conflict.results[0]).toMatchObject({ status: 'conflict', review: true, transaction: { legs: [{ amountMinor: '-100' }] } });
    transactions.create.mockRejectedValueOnce(new TransactionError('TRANSACTION_CONFLICT'));
    const same = await sync.apply('user', { schemaVersion: 1, operations: [createOp(income('-0100'))] } as never);
    expect(same.results[0]).toMatchObject({ status: 'conflict', review: false });
    transactions.update.mockRejectedValueOnce(new TransactionError('TRANSACTION_CONFLICT'));
    transactions.find.mockResolvedValue(bundle('-100'));
    const stale = await sync.apply('user', { schemaVersion: 1, operations: [{ opId: randomUUID(), action: 'update', id: randomUUID(), body: { version: 1, legs: income('-100').legs } }] } as never);
    expect(stale.results[0]).toMatchObject({ status: 'conflict', review: false });
    transactions.delete.mockRejectedValueOnce(new TransactionError('TRANSACTION_CONFLICT'));
    const removed = await sync.apply('user', { schemaVersion: 1, operations: [{ opId: randomUUID(), action: 'delete', id: randomUUID(), version: 1 }] } as never);
    expect(removed.results[0]).toMatchObject({ status: 'conflict', review: false });
  });
});
