import { AccountService } from './account.service';
import { toAccountExport, type ExportSource } from './domain/account-export';
import { AccountPrivacyError } from './domain/account-privacy';
import { PrismaAccountRepository } from './infrastructure/prisma-account.repository';

const at = new Date('2026-10-12T06:00:00.000Z');
const day = new Date('2026-10-12T00:00:00.000Z');
const id = '11111111-1111-4111-8111-111111111111';
const clientId = '22222222-2222-4222-8222-222222222222';

function source(): ExportSource {
  return {
    schemaVersion: 1,
    exportedAt: at,
    user: {
      id, email: 'owner@example.test', locale: 'vi', timezone: 'Asia/Ho_Chi_Minh', defaultCurrencyCode: 'VND',
      displayName: null, fiscalMonthStartDay: 1,
      onboardingGoals: ['save', 'budget'], trackingHabit: 'app', reviewCadence: 'weekly', onboardingBudgetMinor: 15000000n,
      emailVerifiedAt: at, categoriesInitializedAt: null, categoriesSupplementedAt: null, createdAt: at, updatedAt: at,
    },
    oauthProviders: ['apple', 'google'],
    financialAccounts: [{
      id, clientId, name: 'Cash', type: 'cash', currencyCode: 'VND', initialBalanceMinor: 9007199254740993n,
      sortOrder: 0, archivedAt: null, creditLimitMinor: null, statementCloseDay: null, paymentDueDay: null,
      minimumPaymentMinor: null, version: 1, createdAt: at, updatedAt: at,
    }],
    categoryGroups: [],
    categories: [],
    tags: [],
    fxQuotes: [{
      id, clientId, fromCode: 'USD', toCode: 'VND', rate: '25000.00000000', quotedAt: at, source: 'manual',
      version: 1, createdAt: at, updatedAt: at,
    }],
    recurringRules: [],
    bills: [],
    budget: null,
    budgetMonths: [],
    notificationPreferences: null,
    notifications: [],
    transactions: [{
      id, clientId, type: 'expense', amountMinor: -150000n, currencyCode: 'VND', occurredOn: day, occurredTime: '12:40',
      accountId: id, categoryId: null, transferGroupId: null, fxQuoteId: null, recurringRuleId: null,
      notes: 'cafe', merchant: 'WinMart',
      deletedAt: at, tagIds: [clientId, id], version: 2, createdAt: at, updatedAt: at,
    }],
  };
}

describe('BE-P1-010 account export mapping', () => {
  it('serializes money as strings and keeps a deleted transaction', () => {
    const snapshot = toAccountExport(source());
    expect(snapshot).toMatchObject({
      schemaVersion: 1,
      userId: id,
      oauthProviders: ['apple', 'google'],
      profile: {
        email: 'owner@example.test', emailVerifiedAt: at.toISOString(), categoriesInitializedAt: null,
        onboardingGoals: ['save', 'budget'], trackingHabit: 'app', reviewCadence: 'weekly', onboardingBudgetMinor: '15000000',
      },
      financialAccounts: [{
        initialBalanceMinor: '9007199254740993', creditLimitMinor: null, minimumPaymentMinor: null,
      }],
      fxQuotes: [{ rate: '25000.00000000' }],
      transactions: [{
        amountMinor: '-150000', occurredOn: '2026-10-12', occurredTime: '12:40', deletedAt: at.toISOString(), merchant: 'WinMart',
        tagIds: [clientId, id].sort(),
      }],
    });
    expect(JSON.stringify(snapshot)).not.toContain('passwordHash');
    expect(snapshot.transactions[0].tagIds).toEqual([id, clientId].sort());
  });
});

describe('BE-P1-010 account service', () => {
  const snapshot = toAccountExport(source());
  const repository = {
    exportForUser: jest.fn(),
    deleteAccount: jest.fn(),
  };
  const service = new AccountService(repository);

  beforeEach(() => {
    repository.exportForUser.mockReset();
    repository.deleteAccount.mockReset();
  });

  it('returns the snapshot and rejects a missing owner without inventing data', async () => {
    repository.exportForUser.mockResolvedValueOnce(snapshot);
    await expect(service.export(id)).resolves.toBe(snapshot);
    repository.exportForUser.mockResolvedValueOnce(null);
    await expect(service.export(id)).rejects.toMatchObject({ code: 'SESSION_INVALID' });
    repository.exportForUser.mockRejectedValueOnce(new AccountPrivacyError('ACCOUNT_UNAVAILABLE'));
    await expect(service.export(id)).rejects.toMatchObject({ code: 'ACCOUNT_UNAVAILABLE' });
  });

  it('does not report deletion when the repository refuses or fails', async () => {
    repository.deleteAccount.mockResolvedValueOnce(true);
    await expect(service.remove(id)).resolves.toBeUndefined();
    repository.deleteAccount.mockResolvedValueOnce(false);
    await expect(service.remove(id)).rejects.toMatchObject({ code: 'SESSION_INVALID' });
    repository.deleteAccount.mockRejectedValueOnce(new Error('audit down'));
    await expect(service.remove(id)).rejects.toThrow('audit down');
  });
});

describe('BE-P1-010 account repository audit', () => {
  function tx() {
    return {
      $queryRaw: jest.fn().mockResolvedValue([{ id }]),
      schemaMeta: { findUnique: jest.fn().mockResolvedValue({ version: 1 }) },
      user: {
        findUnique: jest.fn().mockResolvedValue({
          id, email: 'owner@example.test', locale: 'vi', timezone: 'Asia/Ho_Chi_Minh', defaultCurrencyCode: 'VND',
          displayName: null, fiscalMonthStartDay: 1, onboardingGoals: [], trackingHabit: null, reviewCadence: null, onboardingBudgetMinor: null,
          emailVerifiedAt: null, categoriesInitializedAt: null, categoriesSupplementedAt: null, createdAt: at, updatedAt: at,
          oauthIdentities: [{ provider: 'google' }],
        }),
        delete: jest.fn(),
      },
      financialAccount: { findMany: jest.fn().mockResolvedValue([]), deleteMany: jest.fn() },
      categoryGroup: { findMany: jest.fn().mockResolvedValue([]), deleteMany: jest.fn() },
      category: { findMany: jest.fn().mockResolvedValue([]), updateMany: jest.fn(), deleteMany: jest.fn() },
      tag: { findMany: jest.fn().mockResolvedValue([]), deleteMany: jest.fn() },
      fxQuote: { findMany: jest.fn().mockResolvedValue([]), deleteMany: jest.fn() },
      recurringRule: { findMany: jest.fn().mockResolvedValue([]), deleteMany: jest.fn() },
      recurringOccurrence: { deleteMany: jest.fn() },
      bill: { findMany: jest.fn().mockResolvedValue([]), deleteMany: jest.fn() },
      budget: { findUnique: jest.fn().mockResolvedValue(null), deleteMany: jest.fn() },
      budgetMonth: { findMany: jest.fn().mockResolvedValue([]), deleteMany: jest.fn() },
      notificationPreference: { findUnique: jest.fn().mockResolvedValue(null), deleteMany: jest.fn() },
      inAppNotification: { findMany: jest.fn().mockResolvedValue([]), deleteMany: jest.fn() },
      transaction: { findMany: jest.fn().mockResolvedValue([]), deleteMany: jest.fn() },
      transactionTag: { deleteMany: jest.fn() },
      auditEvent: { create: jest.fn() },
    };
  }

  function repository(client: ReturnType<typeof tx>) {
    const prisma = { $transaction: jest.fn(async (fn: (value: typeof client) => Promise<unknown>) => fn(client)) };
    return new PrismaAccountRepository(prisma as never);
  }

  it('writes export audit before returning data and omits secrets', async () => {
    const client = tx();
    const snapshot = await repository(client).exportForUser(id);
    expect(client.auditEvent.create).toHaveBeenCalledWith({
      data: expect.objectContaining({ action: 'user.data_export', actorId: id, targetId: id, outcome: 'success' }),
    });
    expect(snapshot?.profile.email).toBe('owner@example.test');
    expect(snapshot).not.toHaveProperty('passwordHash');
    expect(JSON.stringify(snapshot)).not.toContain('subject');
  });

  it('does not return an export when audit fails or the schema row is missing', async () => {
    const failed = tx();
    failed.auditEvent.create.mockRejectedValue(new Error('audit down'));
    await expect(repository(failed).exportForUser(id)).rejects.toThrow('audit down');

    const missing = tx();
    missing.schemaMeta.findUnique.mockResolvedValue(null);
    await expect(repository(missing).exportForUser(id)).rejects.toBeInstanceOf(AccountPrivacyError);
    expect(missing.auditEvent.create).not.toHaveBeenCalled();

    const absent = tx();
    absent.$queryRaw.mockResolvedValue([]);
    await expect(repository(absent).exportForUser(id)).resolves.toBeNull();
    expect(absent.auditEvent.create).not.toHaveBeenCalled();
  });

  it('deletes the user only after the audit row is written', async () => {
    const client = tx();
    await expect(repository(client).deleteAccount(id)).resolves.toBe(true);
    expect(client.auditEvent.create).toHaveBeenCalledWith({
      data: expect.objectContaining({ action: 'user.account_delete', actorType: 'user', outcome: 'success' }),
    });
    expect(client.user.delete).toHaveBeenCalledWith({ where: { id } });
    expect(client.auditEvent.create.mock.invocationCallOrder[0]).toBeLessThan(client.user.delete.mock.invocationCallOrder[0]);

    const failed = tx();
    failed.auditEvent.create.mockRejectedValue(new Error('audit down'));
    await expect(repository(failed).deleteAccount(id)).rejects.toThrow('audit down');
    expect(failed.user.delete).not.toHaveBeenCalled();

    const absent = tx();
    absent.$queryRaw.mockResolvedValue([]);
    await expect(repository(absent).deleteAccount(id)).resolves.toBe(false);
    expect(absent.auditEvent.create).not.toHaveBeenCalled();
    expect(absent.user.delete).not.toHaveBeenCalled();
  });
});
