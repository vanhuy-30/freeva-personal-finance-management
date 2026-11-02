import { randomUUID } from 'node:crypto';
import { PrismaService } from '../src/infrastructure/prisma/prisma.service';
import { PrismaNotificationRepository } from '../src/modules/notifications/infrastructure/prisma-notification.repository';

const databaseUrl = process.env.AUTH_TEST_DATABASE_URL;
if (!databaseUrl || new URL(databaseUrl).pathname !== '/auth_test') {
  throw new Error('AUTH_TEST_DATABASE_URL must point to an isolated database named auth_test');
}
process.env.DATABASE_URL = databaseUrl;

describe('BE-P3-006 daily log context PostgreSQL', () => {
  const prisma = new PrismaService();
  const repository = new PrismaNotificationRepository(prisma);
  const users: string[] = [];
  // 2026-11-02 21:00 ICT; local day is 2026-11-02 in Asia/Ho_Chi_Minh, 2026-11-02 in UTC too.
  const now = new Date('2026-11-02T14:00:00.000Z');

  async function setup(timezone = 'Asia/Ho_Chi_Minh') {
    const id = randomUUID();
    users.push(id);
    await prisma.user.create({
      data: { id, email: `${id}@example.test`, defaultCurrencyCode: 'VND', timezone },
    });
    await prisma.notificationPreference.create({ data: { userId: id, dailyLogEnabled: true } });
    const account = await prisma.financialAccount.create({
      data: {
        userId: id,
        clientId: randomUUID(),
        name: 'Ví',
        type: 'cash',
        currencyCode: 'VND',
        initialBalanceMinor: 0n,
      },
    });
    return { id, accountId: account.id };
  }

  function tx(userId: string, accountId: string, over: Record<string, unknown>) {
    return prisma.transaction.create({
      data: {
        userId,
        accountId,
        clientId: randomUUID(),
        type: 'expense',
        amountMinor: -1000n,
        currencyCode: 'VND',
        occurredOn: new Date('2026-11-02T00:00:00.000Z'),
        ...over,
      },
    });
  }

  beforeAll(async () => {
    await prisma.$connect();
  });

  afterAll(async () => {
    await prisma.transaction.deleteMany({ where: { userId: { in: users } } });
    await prisma.financialAccount.deleteMany({ where: { userId: { in: users } } });
    await prisma.notificationPreference.deleteMany({ where: { userId: { in: users } } });
    await prisma.user.deleteMany({ where: { id: { in: users } } });
    await prisma.$disconnect();
  });

  it('is false with no transaction today', async () => {
    const { id } = await setup();
    await expect(repository.loadEvaluateContext(id, now)).resolves.toMatchObject({ hasTransactionToday: false });
  });

  it('is true for an expense dated today and false for another day', async () => {
    const { id, accountId } = await setup();
    await tx(id, accountId, { occurredOn: new Date('2026-11-01T00:00:00.000Z') });
    expect((await repository.loadEvaluateContext(id, now)).hasTransactionToday).toBe(false);
    await tx(id, accountId, {});
    expect((await repository.loadEvaluateContext(id, now)).hasTransactionToday).toBe(true);
  });

  it('ignores adjustments and soft-deleted rows', async () => {
    const { id, accountId } = await setup();
    await tx(id, accountId, { type: 'adjustment', amountMinor: 500n });
    await tx(id, accountId, { deletedAt: new Date() });
    expect((await repository.loadEvaluateContext(id, now)).hasTransactionToday).toBe(false);
  });

  it('uses the profile timezone for the local day', async () => {
    // 2026-11-02T20:00Z is already 2026-11-03 in Asia/Ho_Chi_Minh.
    const late = new Date('2026-11-02T20:00:00.000Z');
    const { id, accountId } = await setup();
    await tx(id, accountId, {});
    expect((await repository.loadEvaluateContext(id, late)).hasTransactionToday).toBe(false);
    const utc = await setup('UTC');
    await tx(utc.id, utc.accountId, {});
    expect((await repository.loadEvaluateContext(utc.id, late)).hasTransactionToday).toBe(true);
  });
});
