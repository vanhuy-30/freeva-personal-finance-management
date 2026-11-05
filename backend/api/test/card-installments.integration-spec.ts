import { createHash, randomBytes, randomUUID } from 'node:crypto';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { Test } from '@nestjs/testing';
import { PrismaModule } from '../src/infrastructure/prisma/prisma.module';
import { PrismaService } from '../src/infrastructure/prisma/prisma.service';
import { AuthMailWorker } from '../src/modules/auth/infrastructure/auth-mail.worker';
import { CardInstallmentModule } from '../src/modules/card-installments/card-installment.module';
import { FinancialAccountModule } from '../src/modules/financial-accounts/financial-account.module';
import { ReportModule } from '../src/modules/reports/report.module';
import { TransactionModule } from '../src/modules/transactions/transaction.module';

const databaseUrl = process.env.AUTH_TEST_DATABASE_URL;
if (!databaseUrl || new URL(databaseUrl).pathname !== '/auth_test') {
  throw new Error('AUTH_TEST_DATABASE_URL must point to an isolated database named auth_test');
}
process.env.DATABASE_URL = databaseUrl;

describe('BE-P3-009 card installments HTTP + PostgreSQL', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let base: string;
  let owner: string;
  let token: string;
  let otherToken: string;
  const fixtureUsers: string[] = [];

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      imports: [
        ConfigModule.forRoot({ ignoreEnvFile: true, isGlobal: true, load: [() => ({
          AUTH_SECRET_KEY: randomBytes(32).toString('hex'), NODE_ENV: 'test', MAIL_PROVIDER: 'smtp',
          SMTP_HOST: 'localhost', SMTP_PORT: '1025', MAIL_FROM: 'noreply@example.test',
        })] }),
        PrismaModule, FinancialAccountModule, TransactionModule, ReportModule, CardInstallmentModule,
      ],
    }).compile();
    app = module.createNestApplication();
    app.setGlobalPrefix('api');
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));
    await app.listen(0, '127.0.0.1');
    base = await app.getUrl();
    prisma = app.get(PrismaService);
    await app.get(AuthMailWorker).onModuleDestroy();
  });

  async function user() {
    const id = randomUUID();
    fixtureUsers.push(id);
    await prisma.user.create({ data: { id, email: `${id}@example.test`, defaultCurrencyCode: 'VND', timezone: 'Asia/Ho_Chi_Minh' } });
    const bearer = randomBytes(32).toString('hex');
    await prisma.authSession.create({
      data: { userId: id, tokenHash: createHash('sha256').update(bearer).digest('hex'), expiresAt: new Date(Date.now() + 60000) },
    });
    return { id, bearer };
  }

  beforeEach(async () => {
    const first = await user(); const second = await user();
    owner = first.id; token = first.bearer; otherToken = second.bearer;
  });

  afterAll(async () => {
    if (prisma) {
      const where = { userId: { in: fixtureUsers } };
      await prisma.cardInstallmentPlan.deleteMany({ where });
      await prisma.transaction.deleteMany({ where });
      await prisma.category.deleteMany({ where });
      await prisma.financialAccount.deleteMany({ where });
      await prisma.auditEvent.deleteMany({ where: { actorId: { in: fixtureUsers } } });
      await prisma.authSession.deleteMany({ where });
      await prisma.user.deleteMany({ where: { id: { in: fixtureUsers } } });
    }
    await app?.close();
  });

  async function call(method: string, path: string, body?: object, bearer = token, key?: string) {
    const res = await fetch(`${base}/api${path}`, {
      method,
      headers: { Authorization: `Bearer ${bearer}`, ...(body ? { 'Content-Type': 'application/json' } : {}),
        ...(key ? { 'Idempotency-Key': key } : {}) },
      body: body ? JSON.stringify(body) : undefined,
    });
    const text = await res.text();
    return { status: res.status, body: text ? JSON.parse(text) : undefined };
  }

  const card = () => prisma.financialAccount.create({
    data: { userId: owner, clientId: randomUUID(), name: 'Card', type: 'credit', currencyCode: 'VND', initialBalanceMinor: 0n, creditLimitMinor: 50_000_000n },
  });
  const cash = () => prisma.financialAccount.create({
    data: { userId: owner, clientId: randomUUID(), name: 'Cash', type: 'cash', currencyCode: 'VND', initialBalanceMinor: 20_000_000n },
  });
  const category = () => prisma.category.create({ data: { userId: owner, clientId: randomUUID(), name: 'Mua sắm', kind: 'expense' } });
  const balance = async (id: string) => ((await call('GET', `/v1/financial-accounts/${id}`)).body as { balanceMinor: string }).balanceMinor;

  async function purchase(accountId: string, categoryId: string, amount: bigint, occurredOn = '2026-11-01') {
    const clientId = randomUUID();
    const res = await call('POST', '/v1/transactions', { type: 'expense', occurredOn, categoryId,
      legs: [{ clientId, accountId, currencyCode: 'VND', amountMinor: (-amount).toString() }] }, token, clientId);
    expect(res.status).toBe(201);
    return res.body.legs[0] as { id: string; version: number };
  }
  const plan = (transactionId: string, extra: object = {}, clientId: string = randomUUID(), bearer = token) =>
    call('POST', '/v1/card-installments', { clientId, transactionId, installmentCount: 12, firstDueOn: '2026-12-15', ...extra }, bearer);
  const cashflow = async (on: string) => (await call('GET', `/v1/reports/cashflow?period=month&on=${on}`)).body;

  it('turns a card purchase into a schedule without moving any money or touching reports', async () => {
    const wallet = await card(); const cat = await category();
    const bought = await purchase(wallet.id, cat.id, 12_000_000n);
    expect(await balance(wallet.id)).toBe('-12000000');
    const before = await cashflow('2026-11-15');
    const created = await plan(bought.id);
    expect(created.status).toBe(201);
    expect(created.body).toMatchObject({ totalMinor: '12000000', installmentMinor: '1000000', installmentCount: 12, status: 'active', accountId: wallet.id });
    expect(created.body.periods).toHaveLength(12);
    expect(created.body.periods.reduce((sum: bigint, p: { amountMinor: string }) => sum + BigInt(p.amountMinor), 0n)).toBe(12_000_000n);
    expect(created.body.periods[0]).toMatchObject({ dueOn: '2026-12-15', amountMinor: '1000000' });
    expect(created.body.periods[11].dueOn).toBe('2027-11-15');
    // The purchase is still counted once, in the month it was made, and the card debt did not change.
    expect(await balance(wallet.id)).toBe('-12000000');
    expect(await cashflow('2026-11-15')).toEqual(before);
    expect((await cashflow('2026-12-15')).totals?.[0]?.expenseMinor ?? '0').toBe('0');
    expect(await prisma.transaction.count({ where: { userId: owner } })).toBe(1);
  });

  it('keeps the periods summing to the price when it does not divide evenly, and accepts a custom amount', async () => {
    const wallet = await card(); const cat = await category();
    const odd = await purchase(wallet.id, cat.id, 10_000_000n);
    const created = await plan(odd.id, { installmentCount: 3 });
    expect(created.body.periods.map((p: { amountMinor: string }) => p.amountMinor)).toEqual(['3333334', '3333334', '3333332']);
    const custom = await purchase(wallet.id, cat.id, 1_000_000n);
    const second = await plan(custom.id, { installmentCount: 4, installmentMinor: '300000' });
    expect(second.body.periods.map((p: { amountMinor: string }) => p.amountMinor)).toEqual(['300000', '300000', '300000', '100000']);
    const bad = await purchase(wallet.id, cat.id, 1_000_000n);
    expect((await plan(bad.id, { installmentCount: 4, installmentMinor: '100000' })).status).toBe(400);
  });

  it('replays the same request, conflicts on a different one, and allows one plan per purchase', async () => {
    const wallet = await card(); const cat = await category();
    const bought = await purchase(wallet.id, cat.id, 6_000_000n);
    const id = randomUUID();
    const first = await plan(bought.id, { installmentCount: 6 }, id);
    expect(first.status).toBe(201);
    const retry = await plan(bought.id, { installmentCount: 6 }, id);
    expect(retry.status).toBe(200);
    expect(retry.body.id).toBe(first.body.id);
    expect((await plan(bought.id, { installmentCount: 3 }, id)).status).toBe(409);
    expect((await plan(bought.id, { installmentCount: 6 })).status).toBe(409);
    expect(await prisma.cardInstallmentPlan.count({ where: { userId: owner } })).toBe(1);
  });

  it('only plans an active expense on a credit wallet, within the allowed range, owned by the caller', async () => {
    const wallet = await card(); const cat = await category(); const wallet2 = await cash();
    const onCash = await purchase(wallet2.id, cat.id, 1_000_000n);
    expect((await plan(onCash.id)).status).toBe(409);
    const bought = await purchase(wallet.id, cat.id, 1_200_000n);
    expect((await plan(bought.id, { installmentCount: 1 })).status).toBe(400);
    expect((await plan(bought.id, { installmentCount: 61 })).status).toBe(400);
    expect((await plan(bought.id, { firstDueOn: '2026-10-31' })).status).toBe(400);
    expect((await plan(bought.id, { firstDueOn: '2026-02-30' })).status).toBe(400);
    expect((await plan(randomUUID())).status).toBe(400);
    expect((await plan(bought.id, {}, randomUUID(), otherToken)).status).toBe(400);
    const clientId = randomUUID();
    const income = await call('POST', '/v1/transactions', { type: 'income', occurredOn: '2026-11-01',
      legs: [{ clientId, accountId: wallet.id, currencyCode: 'VND', amountMinor: '5000' }] }, token, clientId);
    expect((await plan(income.body.legs[0].id)).status).toBe(409);
  });

  it('reports what falls due per card in a range, so the card amount due can add it', async () => {
    const wallet = await card(); const cat = await category();
    const a = await purchase(wallet.id, cat.id, 12_000_000n); const b = await purchase(wallet.id, cat.id, 600_000n);
    await plan(a.id); await plan(b.id, { installmentCount: 2, firstDueOn: '2026-12-20' });
    const december = await call('GET', '/v1/card-installments/due?from=2026-12-01&to=2026-12-31');
    expect(december.body.items).toEqual([{ accountId: wallet.id, currencyCode: 'VND', dueMinor: '1300000', planCount: 2 }]);
    const february = await call('GET', '/v1/card-installments/due?from=2027-02-01&to=2027-02-28');
    expect(february.body.items).toEqual([{ accountId: wallet.id, currencyCode: 'VND', dueMinor: '1000000', planCount: 1 }]);
    expect((await call('GET', '/v1/card-installments/due?from=2026-12-31&to=2026-12-01')).status).toBe(400);
    expect((await call('GET', '/v1/card-installments/due?from=2026-12-01&to=2026-12-31', undefined, otherToken)).body.items).toEqual([]);
  });

  it('closing stops the schedule, keeps the purchase, and the card debt only moves through a transfer', async () => {
    const wallet = await card(); const source = await cash(); const cat = await category();
    const bought = await purchase(wallet.id, cat.id, 12_000_000n);
    const created = await plan(bought.id);
    const closed = await call('POST', `/v1/card-installments/${created.body.id}/close`, { version: created.body.version });
    expect(closed.status).toBe(200);
    expect(closed.body).toMatchObject({ status: 'closed', remainingCount: 0, nextDueOn: null });
    expect(closed.body.periods.every((p: { state: string }) => p.state === 'closed')).toBe(true);
    expect((await call('POST', `/v1/card-installments/${created.body.id}/close`, { version: closed.body.version })).status).toBe(409);
    expect((await call('GET', '/v1/card-installments/due?from=2026-12-01&to=2027-12-31')).body.items).toEqual([]);
    expect((await call('GET', `/v1/card-installments?status=active`)).body.items).toEqual([]);
    expect((await call('GET', `/v1/card-installments/${created.body.id}`, undefined, otherToken)).status).toBe(404);
    expect(await balance(wallet.id)).toBe('-12000000');
    // Paying one period is the usual wallet -> card transfer; the debt drops by exactly that.
    const out = randomUUID();
    const pay = await call('POST', '/v1/transactions', { type: 'transfer', occurredOn: '2026-12-15', legs: [
      { clientId: out, accountId: source.id, currencyCode: 'VND', amountMinor: '-1000000' },
      { clientId: randomUUID(), accountId: wallet.id, currencyCode: 'VND', amountMinor: '1000000' }] }, token, out);
    expect(pay.status).toBe(201);
    expect(await balance(wallet.id)).toBe('-11000000');
    expect(await balance(source.id)).toBe('19000000');
    const own = await prisma.transaction.findFirstOrThrow({ where: { id: bought.id } });
    expect(own.amountMinor).toBe(-12_000_000n);
    expect(own.deletedAt).toBeNull();
  });

  it('previews the schedule a create would make without writing, with the same checks', async () => {
    const wallet = await card(); const cat = await category(); const wallet2 = await cash();
    const bought = await purchase(wallet.id, cat.id, 10_000_000n);
    const preview = (extra: object = {}, bearer = token) =>
      call('POST', '/v1/card-installments/preview', { transactionId: bought.id, installmentCount: 3, firstDueOn: '2026-11-25', ...extra }, bearer);
    const even = await preview();
    expect(even.status).toBe(200);
    expect(even.body).toMatchObject({ transactionId: bought.id, accountId: wallet.id, currencyCode: 'VND', totalMinor: '10000000',
      installmentMinor: '3333334', installmentCount: 3, firstDueOn: '2026-11-25', lastDueOn: '2027-01-25' });
    expect(even.body.periods.map((p: { amountMinor: string }) => p.amountMinor)).toEqual(['3333334', '3333334', '3333332']);
    expect((await preview({ installmentMinor: '4000000' })).body.periods.map((p: { amountMinor: string }) => p.amountMinor))
      .toEqual(['4000000', '4000000', '2000000']);
    expect((await preview({ installmentMinor: '1000000' })).status).toBe(400);
    expect((await preview({ firstDueOn: '2026-10-31' })).status).toBe(400);
    expect((await preview({}, otherToken)).status).toBe(400);
    expect(await prisma.cardInstallmentPlan.count({ where: { userId: owner } })).toBe(0);
    const onCash = await purchase(wallet2.id, cat.id, 1_000_000n);
    expect((await call('POST', '/v1/card-installments/preview', { transactionId: onCash.id, installmentCount: 3, firstDueOn: '2026-11-25' })).status).toBe(409);
    const created = await plan(bought.id, { installmentCount: 3, firstDueOn: '2026-11-25' });
    expect(created.body.periods.map((p: { amountMinor: string }) => p.amountMinor)).toEqual(['3333334', '3333334', '3333332']);
    expect((await preview()).status).toBe(409);
  });

  it('names the purchase on the plan and links the plan from the expense', async () => {
    const wallet = await card(); const cat = await category();
    const clientId = randomUUID();
    const res = await call('POST', '/v1/transactions', { type: 'expense', occurredOn: '2026-10-12', categoryId: cat.id, merchant: 'Điện thoại', notes: 'trả góp 0%',
      legs: [{ clientId, accountId: wallet.id, currencyCode: 'VND', amountMinor: '-24000000' }] }, token, clientId);
    const bought = res.body.legs[0] as { id: string };
    const other = await purchase(wallet.id, cat.id, 500_000n);
    const created = await plan(bought.id, { installmentCount: 6, firstDueOn: '2026-11-25' });
    expect(created.body).toMatchObject({ purchaseOn: '2026-10-12', purchaseMerchant: 'Điện thoại', purchaseNote: 'trả góp 0%', purchaseCategoryId: cat.id });
    const listed = await call('GET', `/v1/card-installments?accountId=${wallet.id}`);
    expect(listed.body.items[0]).toMatchObject({ purchaseOn: '2026-10-12', purchaseMerchant: 'Điện thoại', purchaseNote: 'trả góp 0%', purchaseCategoryId: cat.id });
    const detail = await call('GET', `/v1/transactions/${bought.id}`);
    expect(detail.body.legs[0].installmentPlanId).toBe(created.body.id);
    const list = await call('GET', `/v1/transactions?accountId=${wallet.id}`);
    const byId = new Map((list.body.items as { id: string; installmentPlanId: string | null }[]).map(item => [item.id, item.installmentPlanId]));
    expect(byId.get(bought.id)).toBe(created.body.id);
    expect(byId.get(other.id)).toBeNull();
    // Closed: the expense is free again, and a new plan replaces the closed one.
    await call('POST', `/v1/card-installments/${created.body.id}/close`, { version: created.body.version });
    expect((await call('GET', `/v1/transactions/${bought.id}`)).body.legs[0].installmentPlanId).toBeNull();
    expect((await call('POST', '/v1/card-installments/preview', { transactionId: bought.id, installmentCount: 3, firstDueOn: '2026-11-25' })).status).toBe(200);
    const again = await plan(bought.id, { installmentCount: 3, firstDueOn: '2026-11-25' });
    expect(again.status).toBe(201);
    expect(again.body.id).not.toBe(created.body.id);
    expect((await call('GET', `/v1/card-installments/${created.body.id}`)).status).toBe(404);
    expect((await call('GET', `/v1/transactions/${bought.id}`)).body.legs[0].installmentPlanId).toBe(again.body.id);
    expect((await plan(bought.id, { installmentCount: 6, firstDueOn: '2026-11-25' })).status).toBe(409);
  });

  it('closes the plan when its purchase is deleted', async () => {
    const wallet = await card(); const cat = await category();
    const bought = await purchase(wallet.id, cat.id, 3_000_000n);
    const created = await plan(bought.id, { installmentCount: 3 });
    expect((await call('DELETE', `/v1/transactions/${bought.id}?version=${bought.version}`)).status).toBe(204);
    const after = await call('GET', `/v1/card-installments/${created.body.id}`);
    expect(after.body).toMatchObject({ status: 'closed', remainingCount: 0 });
  });
});
