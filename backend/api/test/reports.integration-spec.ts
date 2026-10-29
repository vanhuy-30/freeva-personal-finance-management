import { createHash, randomBytes, randomUUID } from 'node:crypto';
import { Writable } from 'node:stream';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { Test } from '@nestjs/testing';
import { LoggerModule } from 'nestjs-pino';
import { httpRequestSerializer } from '../src/core/logging/http-request.serializer';
import { pinoRedactOptions } from '../src/core/logging/pino-redact';
import { PrismaModule } from '../src/infrastructure/prisma/prisma.module';
import { PrismaService } from '../src/infrastructure/prisma/prisma.service';
import { AuthMailWorker } from '../src/modules/auth/infrastructure/auth-mail.worker';
import { ReportModule } from '../src/modules/reports/report.module';

const databaseUrl = process.env.AUTH_TEST_DATABASE_URL;
if (!databaseUrl || new URL(databaseUrl).pathname !== '/auth_test') {
  throw new Error('AUTH_TEST_DATABASE_URL must point to an isolated database named auth_test');
}
process.env.DATABASE_URL = databaseUrl;

describe('BE-P1-007 / BE-P2-E06 HTTP + PostgreSQL', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let base: string;
  let owner: string;
  let other: string;
  let token: string;
  let otherToken: string;
  let logs = '';
  const fixtureUsers: string[] = [];
  const stream = new Writable({ write(chunk, _encoding, callback) { logs += chunk.toString(); callback(); } });
  const walletName = 'Secret wallet label';
  const huge = 9007199254740993n;

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      imports: [
        ConfigModule.forRoot({ ignoreEnvFile: true, isGlobal: true, load: [() => ({
          AUTH_SECRET_KEY: randomBytes(32).toString('hex'), NODE_ENV: 'test', MAIL_PROVIDER: 'smtp',
          SMTP_HOST: 'localhost', SMTP_PORT: '1025', MAIL_FROM: 'noreply@example.test',
        })] }),
        LoggerModule.forRoot({ pinoHttp: [{ serializers: { req: httpRequestSerializer }, redact: pinoRedactOptions }, stream] }),
        PrismaModule, ReportModule,
      ],
    }).compile();
    app = module.createNestApplication();
    app.setGlobalPrefix('api');
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));
    await app.listen(0, '127.0.0.1');
    base = await app.getUrl();
    prisma = app.get(PrismaService);
    await app.get(AuthMailWorker).onModuleDestroy();
    for (const currency of [
      { code: 'VND', minorDigits: 0, name: 'Dong' },
      { code: 'USD', minorDigits: 2, name: 'US Dollar' },
    ]) await prisma.currency.upsert({ where: { code: currency.code }, create: currency, update: {} });
  });

  async function user(timezone = 'Asia/Ho_Chi_Minh', fiscalMonthStartDay = 1) {
    const id = randomUUID();
    fixtureUsers.push(id);
    await prisma.user.create({ data: { id, email: `${id}@example.test`, defaultCurrencyCode: 'VND', timezone, fiscalMonthStartDay } });
    const bearer = randomBytes(32).toString('hex');
    await prisma.authSession.create({ data: { userId: id, tokenHash: createHash('sha256').update(bearer).digest('hex'), expiresAt: new Date(Date.now() + 60_000) } });
    return { id, bearer };
  }

  beforeEach(async () => {
    const first = await user('Asia/Ho_Chi_Minh', 15);
    const second = await user();
    owner = first.id;
    other = second.id;
    token = first.bearer;
    otherToken = second.bearer;
    logs = '';
  });

  afterAll(async () => {
    if (prisma) {
      await prisma.transaction.deleteMany({ where: { userId: { in: fixtureUsers } } });
      await prisma.category.deleteMany({ where: { userId: { in: fixtureUsers }, parentId: { not: null } } });
      await prisma.category.deleteMany({ where: { userId: { in: fixtureUsers } } });
      await prisma.financialAccount.deleteMany({ where: { userId: { in: fixtureUsers } } });
      await prisma.authSession.deleteMany({ where: { userId: { in: fixtureUsers } } });
      await prisma.user.deleteMany({ where: { id: { in: fixtureUsers } } });
    }
    await app?.close();
  });

  async function request(path: string, bearer = token) {
    const res = await fetch(`${base}/api/v1/reports${path}`, { headers: bearer ? { Authorization: `Bearer ${bearer}` } : {} });
    const text = await res.text();
    expect(res.headers.get('cache-control')).toBe('no-store');
    return { status: res.status, body: text ? JSON.parse(text) as Record<string, unknown> : undefined, text };
  }

  async function account(type: 'cash' | 'bank' | 'ewallet' | 'credit', currencyCode: string, initialBalanceMinor: bigint, archived = false) {
    return prisma.financialAccount.create({ data: {
      userId: owner, clientId: randomUUID(), name: walletName, type, currencyCode, initialBalanceMinor,
      ...(archived ? { archivedAt: new Date('2026-01-01T00:00:00Z') } : {}),
    } });
  }

  async function category(name: string, parentId?: string, archived = false) {
    return prisma.category.create({ data: {
      userId: owner, clientId: randomUUID(), name, parentId,
      ...(archived ? { archivedAt: new Date('2026-01-01T00:00:00Z') } : {}),
    } });
  }

  async function transaction(input: {
    accountId: string; currencyCode: string; type: 'income' | 'expense' | 'transfer'; amountMinor: bigint;
    occurredOn: string; categoryId?: string; deleted?: boolean; transferGroupId?: string; merchant?: string | null;
  }) {
    return prisma.transaction.create({ data: {
      userId: owner, clientId: randomUUID(), accountId: input.accountId, currencyCode: input.currencyCode,
      type: input.type, amountMinor: input.amountMinor, occurredOn: new Date(`${input.occurredOn}T00:00:00.000Z`),
      categoryId: input.categoryId, transferGroupId: input.transferGroupId, merchant: input.merchant ?? null,
      ...(input.deleted ? { deletedAt: new Date('2026-10-01T00:00:00.000Z') } : {}),
      notes: 'Private report note',
    } });
  }

  it('reports a fiscal month without counting transfers, other owners, or soft-deleted rows', async () => {
    const parent = await category('Parent');
    const child = await category('Child', parent.id, true);
    const cash = await account('cash', 'VND', huge);
    const card = await account('credit', 'VND', 0n);
    const bank = await account('bank', 'VND', 0n);
    const closed = await account('ewallet', 'VND', 20n, true);
    const idle = await account('cash', 'USD', 0n);
    const usd = await account('cash', 'USD', 0n);
    const hidden = await account('cash', 'VND', 0n, true);
    const group = randomUUID();
    await transaction({ accountId: cash.id, currencyCode: 'VND', type: 'income', amountMinor: 1000n, occurredOn: '2026-09-15' });
    await transaction({ accountId: cash.id, currencyCode: 'VND', type: 'income', amountMinor: 9999n, occurredOn: '2026-09-14', deleted: true });
    await transaction({ accountId: cash.id, currencyCode: 'VND', type: 'income', amountMinor: 50n, occurredOn: '2026-10-15' });
    await transaction({ accountId: card.id, currencyCode: 'VND', type: 'expense', amountMinor: -400n, occurredOn: '2026-10-14', categoryId: child.id });
    await transaction({ accountId: cash.id, currencyCode: 'VND', type: 'transfer', amountMinor: -1500n, occurredOn: '2026-10-01', transferGroupId: group });
    await transaction({ accountId: bank.id, currencyCode: 'VND', type: 'transfer', amountMinor: 1500n, occurredOn: '2026-10-01', transferGroupId: group });
    const fx = randomUUID();
    await transaction({ accountId: usd.id, currencyCode: 'USD', type: 'transfer', amountMinor: -1000n, occurredOn: '2026-10-02', transferGroupId: fx });
    await transaction({ accountId: cash.id, currencyCode: 'VND', type: 'transfer', amountMinor: 25000000n, occurredOn: '2026-10-02', transferGroupId: fx });
    await transaction({ accountId: closed.id, currencyCode: 'VND', type: 'expense', amountMinor: -5n, occurredOn: '2026-10-03', categoryId: child.id });
    await transaction({ accountId: usd.id, currencyCode: 'USD', type: 'income', amountMinor: 2500n, occurredOn: '2026-10-04' });

    const report = await request('/cashflow?period=month&on=2026-10-08');
    expect(report.status).toBe(200);
    expect(report.body).toMatchObject({
      period: { kind: 'month', from: '2026-09-15', to: '2026-10-14', timezone: 'Asia/Ho_Chi_Minh', fiscalMonthStartDay: 15 },
      totals: [
        { currency: 'USD', incomeMinor: '2500', expenseMinor: '0', netMinor: '2500', savingsRateBps: 10000 },
        { currency: 'VND', incomeMinor: '1000', expenseMinor: '-405', netMinor: '595', savingsRateBps: 5950 },
      ],
      comparison: { from: '2026-08-15', to: '2026-09-14' },
      topMerchants: [],
    });
    const categories = report.body?.byCategory as { categoryId: string | null; parentId: string | null; expenseMinor: string }[];
    expect(categories).toEqual(expect.arrayContaining([
      expect.objectContaining({ categoryId: null, parentId: null, currency: 'VND', incomeMinor: '1000', expenseMinor: '0' }),
      expect.objectContaining({ categoryId: child.id, parentId: parent.id, currency: 'VND', incomeMinor: '0', expenseMinor: '-405', transactionCount: 2 }),
      expect.objectContaining({ categoryId: null, parentId: null, currency: 'USD', incomeMinor: '2500', expenseMinor: '0' }),
    ]));
    expect(categories.find(row => row.categoryId === parent.id)).toBeUndefined();
    const accounts = report.body?.byAccount as { accountId: string; transferMinor: string; netMinor: string }[];
    expect(accounts.map(row => row.accountId).sort()).toEqual([cash.id, card.id, bank.id, closed.id, idle.id, usd.id].sort());
    expect(accounts.find(row => row.accountId === hidden.id)).toBeUndefined();
    expect(accounts.find(row => row.accountId === cash.id)).toMatchObject({ incomeMinor: '1000', expenseMinor: '0', transferMinor: '24998500' });
    expect(accounts.find(row => row.accountId === bank.id)?.transferMinor).toBe('1500');
    expect(accounts.find(row => row.accountId === usd.id)).toMatchObject({ incomeMinor: '2500', transferMinor: '-1000', netMinor: '1500' });
    expect(accounts.find(row => row.accountId === idle.id)?.netMinor).toBe('0');
    expect(JSON.stringify(report.body)).not.toContain(owner);
    expect(JSON.stringify(report.body)).not.toContain(walletName);
    const other = await request('/cashflow?period=month&on=2026-10-08', otherToken);
    expect(other.body).toMatchObject({ totals: [], byCategory: [], byAccount: [] });
  });

  it('filters week and range on calendar dates and rejects invalid queries', async () => {
    const cash = await account('cash', 'VND', 0n);
    await transaction({ accountId: cash.id, currencyCode: 'VND', type: 'income', amountMinor: 7n, occurredOn: '2026-10-05' });
    await transaction({ accountId: cash.id, currencyCode: 'VND', type: 'income', amountMinor: 8n, occurredOn: '2026-10-04' });
    await transaction({ accountId: cash.id, currencyCode: 'VND', type: 'income', amountMinor: 9n, occurredOn: '2026-10-11' });
    await transaction({ accountId: cash.id, currencyCode: 'VND', type: 'income', amountMinor: 10n, occurredOn: '2026-10-12' });
    const week = await request('/cashflow?period=week&on=2026-10-08');
    expect(week.body).toMatchObject({
      period: { kind: 'week', from: '2026-10-05', to: '2026-10-11' },
      totals: [{ currency: 'VND', incomeMinor: '16', expenseMinor: '0', netMinor: '16', savingsRateBps: 10000 }],
      comparison: { from: '2026-09-28', to: '2026-10-04' },
    });
    const range = await request('/cashflow?period=range&from=2024-02-29&to=2024-02-29');
    expect(range.status).toBe(200);
    expect(range.body).toMatchObject({ period: { kind: 'range', from: '2024-02-29', to: '2024-02-29' }, totals: [] });
    for (const path of [
      '/cashflow?period=month&on=2026-02-29',
      '/cashflow?period=range&from=2026-10-02&to=2026-10-01',
      '/cashflow?period=week&from=2026-10-05&to=2026-10-11',
      '/cashflow?period=range&on=2026-10-08&from=2026-10-01&to=2026-10-02',
      '/cashflow?period=decade',
      '/cashflow?period=year&from=2026-01-01',
      '/trend?period=range',
      '/trend?period=week&from=2026-10-01',
      '/series?window=decade',
      '/series?window=7d&from=2026-10-01',
      '/cashflow?period=month&userId=x',
      '/net-worth?period=month',
    ]) {
      const rejected = await request(path);
      expect(rejected.status).toBe(400);
      expect(rejected.text).not.toContain('2026-02-29');
      expect(rejected.body).toMatchObject({ error: { code: 'VALIDATION_ERROR', details: [] } });
    }
    expect((await request('/cashflow?period=month&on=2026-10-08', '')).status).toBe(401);
  });

  it('returns current signed net worth per currency, including archived accounts and excluding deleted transactions', async () => {
    const cash = await account('cash', 'VND', huge);
    const bank = await account('bank', 'VND', -150n);
    const card = await account('credit', 'VND', -300n);
    const stored = await account('ewallet', 'USD', 80n, true);
    const foreign = await prisma.financialAccount.create({ data: { userId: other, clientId: randomUUID(), name: walletName, type: 'cash', currencyCode: 'VND', initialBalanceMinor: 999999n } });
    await transaction({ accountId: cash.id, currencyCode: 'VND', type: 'expense', amountMinor: -20n, occurredOn: '2020-01-01', categoryId: (await category('Food')).id });
    await transaction({ accountId: cash.id, currencyCode: 'VND', type: 'income', amountMinor: 5000n, occurredOn: '2020-01-02', deleted: true });
    await transaction({ accountId: card.id, currencyCode: 'VND', type: 'expense', amountMinor: -400n, occurredOn: '2020-01-03', categoryId: (await category('Travel')).id });
    await transaction({ accountId: stored.id, currencyCode: 'USD', type: 'income', amountMinor: 20n, occurredOn: '2020-01-04' });
    const report = await request('/net-worth');
    expect(report.status).toBe(200);
    // Hidden (archived) wallets stay out of the total; USD has no active wallet.
    expect(report.body).toEqual({ items: [
      { currency: 'VND', assetsMinor: (huge - 150n - 20n).toString(), liabilitiesMinor: '-700', netWorthMinor: (huge - 150n - 20n - 700n).toString() },
    ] });
    expect(JSON.stringify(report.body)).not.toContain(foreign.id);
    expect((await request('/net-worth', otherToken)).body).toEqual({ items: [
      { currency: 'VND', assetsMinor: '999999', liabilitiesMinor: '0', netWorthMinor: '999999' },
    ] });
    for (const secret of [token, walletName, 'Private report note', huge.toString(), '999999']) expect(logs).not.toContain(secret);
  });

  it('reports a calendar year and a six-month fiscal trend in one call', async () => {
    await prisma.user.update({ where: { id: owner }, data: { fiscalMonthStartDay: 15 } });
    const cash = await account('cash', 'VND', 0n);
    await transaction({ accountId: cash.id, currencyCode: 'VND', type: 'expense', amountMinor: -300n, occurredOn: '2026-10-14' });
    await transaction({ accountId: cash.id, currencyCode: 'VND', type: 'expense', amountMinor: -200n, occurredOn: '2026-09-15' });
    await transaction({ accountId: cash.id, currencyCode: 'VND', type: 'income', amountMinor: 900n, occurredOn: '2026-09-16' });
    await transaction({ accountId: cash.id, currencyCode: 'VND', type: 'expense', amountMinor: -100n, occurredOn: '2025-03-01' });
    await transaction({ accountId: cash.id, currencyCode: 'VND', type: 'expense', amountMinor: -999n, occurredOn: '2026-10-01', deleted: true });
    await transaction({ accountId: cash.id, currencyCode: 'VND', type: 'transfer', amountMinor: -50n, occurredOn: '2026-10-01', transferGroupId: randomUUID() });
    const year = await request('/cashflow?period=year&on=2026-06-01');
    expect(year.body).toMatchObject({
      period: { kind: 'year', from: '2026-01-01', to: '2026-12-31' },
      totals: [{ currency: 'VND', incomeMinor: '900', expenseMinor: '-500', netMinor: '400', savingsRateBps: 4444 }],
      comparison: { from: '2025-01-01', to: '2025-12-31', totals: [{ currency: 'VND', incomeMinor: '0', expenseMinor: '-100', netMinor: '-100', savingsRateBps: null }] },
    });
    const months = await request('/trend?period=month&on=2026-10-08');
    expect(months.status).toBe(200);
    const buckets = months.body?.buckets as { from: string; to: string; totals: unknown[] }[];
    expect(buckets).toHaveLength(6);
    expect(buckets[5]).toEqual({ from: '2026-09-15', to: '2026-10-14', totals: [{ currency: 'VND', incomeMinor: '900', expenseMinor: '-500' }] });
    expect(buckets[4].totals).toEqual([]);
    const years = await request('/trend?period=year&on=2026-10-08');
    expect((years.body?.buckets as { from: string }[]).map(bucket => bucket.from)).toEqual(['2025-01-01', '2026-01-01']);
    expect((await request('/trend?period=week')).status).toBe(200);
    expect((await request('/trend?period=week', otherToken)).body).toMatchObject({ kind: 'week' });
    expect(JSON.stringify((await request('/trend?period=week', otherToken)).body)).not.toContain('900');
    expect((await request('/trend?period=week', '')).status).toBe(401);
  });

  it('uses the profile timezone when the anchor is omitted', async () => {
    await prisma.user.update({ where: { id: owner }, data: { timezone: 'Pacific/Kiritimati', fiscalMonthStartDay: 1 } });
    const report = await request('/cashflow?period=week');
    const parts = new Intl.DateTimeFormat('en-US', { timeZone: 'Pacific/Kiritimati', year: 'numeric', month: '2-digit', day: '2-digit' }).formatToParts(new Date());
    const today = `${parts.find(part => part.type === 'year')?.value}-${parts.find(part => part.type === 'month')?.value}-${parts.find(part => part.type === 'day')?.value}`;
    const period = report.body?.period as { from: string; to: string; timezone: string; fiscalMonthStartDay: number };
    expect(report.status).toBe(200);
    expect(period.timezone).toBe('Pacific/Kiritimati');
    expect(period.fiscalMonthStartDay).toBe(1);
    expect(period.from <= today && today <= period.to).toBe(true);
  });

  it('compares the previous fiscal month, ranks top merchants, and returns 7d and 3m series', async () => {
    await prisma.user.update({ where: { id: owner }, data: { fiscalMonthStartDay: 15 } });
    const cash = await account('cash', 'VND', 0n);
    const usd = await account('cash', 'USD', 0n);
    const food = await category('Food');
    await transaction({ accountId: cash.id, currencyCode: 'VND', type: 'income', amountMinor: 1000n, occurredOn: '2026-09-20' });
    await transaction({ accountId: cash.id, currencyCode: 'VND', type: 'expense', amountMinor: -400n, occurredOn: '2026-09-21', categoryId: food.id, merchant: 'WinMart' });
    await transaction({ accountId: cash.id, currencyCode: 'VND', type: 'expense', amountMinor: -100n, occurredOn: '2026-09-22', categoryId: food.id, merchant: 'Grab' });
    await transaction({ accountId: cash.id, currencyCode: 'VND', type: 'expense', amountMinor: -50n, occurredOn: '2026-09-23', categoryId: food.id, merchant: 'Grab' });
    await transaction({ accountId: cash.id, currencyCode: 'VND', type: 'expense', amountMinor: -20n, occurredOn: '2026-09-24', categoryId: food.id });
    await transaction({ accountId: cash.id, currencyCode: 'VND', type: 'expense', amountMinor: -999n, occurredOn: '2026-09-25', categoryId: food.id, merchant: 'SecretShop', deleted: true });
    await transaction({ accountId: cash.id, currencyCode: 'VND', type: 'income', amountMinor: 200n, occurredOn: '2026-08-20' });
    await transaction({ accountId: cash.id, currencyCode: 'VND', type: 'expense', amountMinor: -100n, occurredOn: '2026-08-21', categoryId: food.id, merchant: 'Old' });
    await transaction({ accountId: usd.id, currencyCode: 'USD', type: 'expense', amountMinor: -15n, occurredOn: '2026-09-20', categoryId: food.id, merchant: 'Amazon' });
    await transaction({ accountId: cash.id, currencyCode: 'VND', type: 'expense', amountMinor: -30n, occurredOn: '2026-10-07', categoryId: food.id, merchant: 'Cafe' });
    await transaction({ accountId: cash.id, currencyCode: 'VND', type: 'income', amountMinor: 5n, occurredOn: '2026-10-02' });

    const report = await request('/cashflow?period=month&on=2026-10-08');
    expect(report.status).toBe(200);
    // Current VND: income 1000+5, expense -400-100-50-20-30 = -600; previous VND expense -100 → delta 50000 bps.
    expect(report.body).toMatchObject({
      period: { from: '2026-09-15', to: '2026-10-14' },
      totals: expect.arrayContaining([
        expect.objectContaining({ currency: 'VND', incomeMinor: '1005', expenseMinor: '-600', netMinor: '405', savingsRateBps: 4029 }),
        expect.objectContaining({ currency: 'USD', incomeMinor: '0', expenseMinor: '-15', netMinor: '-15', savingsRateBps: null }),
      ]),
      comparison: {
        from: '2026-08-15',
        to: '2026-09-14',
        totals: [{ currency: 'VND', incomeMinor: '200', expenseMinor: '-100', netMinor: '100', savingsRateBps: 5000 }],
        expenseDeltaBps: expect.arrayContaining([
          { currency: 'VND', deltaBps: 50000 },
          { currency: 'USD', deltaBps: null },
        ]),
      },
    });
    const merchants = report.body?.topMerchants as { currency: string; merchant: string; expenseMinor: string; transactionCount: number }[];
    expect(merchants).toEqual([
      { currency: 'USD', merchant: 'Amazon', expenseMinor: '-15', transactionCount: 1 },
      { currency: 'VND', merchant: 'WinMart', expenseMinor: '-400', transactionCount: 1 },
      { currency: 'VND', merchant: 'Grab', expenseMinor: '-150', transactionCount: 2 },
      { currency: 'VND', merchant: 'Cafe', expenseMinor: '-30', transactionCount: 1 },
    ]);
    expect(JSON.stringify(report.body)).not.toContain('SecretShop');
    expect(JSON.stringify(report.body)).not.toContain('Private report note');

    const days = await request('/series?window=7d&on=2026-10-08');
    expect(days.status).toBe(200);
    const dayBuckets = days.body?.buckets as { from: string; to: string; totals: { currency: string; incomeMinor: string; expenseMinor: string }[] }[];
    expect(days.body).toMatchObject({ window: '7d' });
    expect(dayBuckets).toHaveLength(7);
    expect(dayBuckets[0]).toEqual({ from: '2026-10-02', to: '2026-10-02', totals: [{ currency: 'VND', incomeMinor: '5', expenseMinor: '0' }] });
    expect(dayBuckets[5]).toEqual({ from: '2026-10-07', to: '2026-10-07', totals: [{ currency: 'VND', incomeMinor: '0', expenseMinor: '-30' }] });
    expect(dayBuckets[6].totals).toEqual([]);

    const months = await request('/series?window=3m&on=2026-10-08');
    expect(months.status).toBe(200);
    const monthBuckets = months.body?.buckets as { from: string; totals: unknown[] }[];
    expect(months.body).toMatchObject({ window: '3m' });
    expect(monthBuckets.map(bucket => bucket.from)).toEqual(['2026-07-15', '2026-08-15', '2026-09-15']);
    expect(monthBuckets[1].totals).toEqual([{ currency: 'VND', incomeMinor: '200', expenseMinor: '-100' }]);
    expect(monthBuckets[2].totals).toEqual(expect.arrayContaining([
      expect.objectContaining({ currency: 'VND', incomeMinor: '1005', expenseMinor: '-600' }),
      expect.objectContaining({ currency: 'USD', incomeMinor: '0', expenseMinor: '-15' }),
    ]));
    expect((await request('/series?window=7d', otherToken)).body).toMatchObject({ window: '7d' });
    expect(JSON.stringify((await request('/series?window=7d', otherToken)).body)).not.toContain('WinMart');
    expect((await request('/series?window=7d', '')).status).toBe(401);
    for (const secret of [token, 'WinMart', 'SecretShop', 'Private report note', '1005']) expect(logs).not.toContain(secret);
  });
});
