import { randomUUID } from 'node:crypto';
import { PrismaService } from '../src/infrastructure/prisma/prisma.service';
import { PrismaCategorySuggestionRepository } from '../src/modules/category-suggestions/infrastructure/prisma-category-suggestion.repository';

const databaseUrl = process.env.AUTH_TEST_DATABASE_URL;
if (!databaseUrl || new URL(databaseUrl).pathname !== '/auth_test') {
  throw new Error('AUTH_TEST_DATABASE_URL must point to an isolated database named auth_test');
}
process.env.DATABASE_URL = databaseUrl;

describe('BE-P5-E03 category suggestions PostgreSQL', () => {
  const prisma = new PrismaService();
  const repository = new PrismaCategorySuggestionRepository(prisma);
  const users: string[] = [];

  async function setup() {
    const id = randomUUID();
    users.push(id);
    await prisma.user.create({ data: { id, email: `${id}@example.test`, defaultCurrencyCode: 'VND' } });
    const account = await prisma.financialAccount.create({
      data: { userId: id, clientId: randomUUID(), name: 'Ví', type: 'cash', currencyCode: 'VND', initialBalanceMinor: 0n },
    });
    const category = (name: string, iconToken: string) => prisma.category.create({
      data: { userId: id, clientId: randomUUID(), name, iconToken, kind: 'expense', isSystem: true },
    });
    return { id, accountId: account.id, coffee: await category('Cà phê', 'coffee'), food: await category('Ăn uống', 'food') };
  }

  const tx = (userId: string, accountId: string, over: Record<string, unknown>) => prisma.transaction.create({
    data: {
      userId, accountId, clientId: randomUUID(), type: 'expense', amountMinor: -45000n, currencyCode: 'VND',
      occurredOn: new Date('2026-11-01T00:00:00.000Z'), ...over,
    },
  });

  beforeAll(() => prisma.$connect());
  afterAll(async () => {
    await prisma.categorySuggestionMapping.deleteMany({ where: { userId: { in: users } } });
    await prisma.transaction.deleteMany({ where: { userId: { in: users } } });
    await prisma.category.deleteMany({ where: { userId: { in: users } } });
    await prisma.financialAccount.deleteMany({ where: { userId: { in: users } } });
    await prisma.user.deleteMany({ where: { id: { in: users } } });
    await prisma.categorySuggestionStat.deleteMany({ where: { day: new Date('2001-01-01T00:00:00Z') } });
    await prisma.$disconnect();
  });

  it('reads history by merchant ignoring case and spaces, newest first, live expenses only', async () => {
    const { id, accountId, coffee, food } = await setup();
    const other = await setup();
    await tx(id, accountId, { merchant: 'highlands  coffee', categoryId: food.id, occurredOn: new Date('2026-10-01T00:00:00Z') });
    await tx(id, accountId, { merchant: 'Highlands Coffee', categoryId: coffee.id, occurredOn: new Date('2026-11-05T00:00:00Z') });
    await tx(id, accountId, { merchant: 'Highlands Coffee', categoryId: coffee.id, deletedAt: new Date() });
    await tx(id, accountId, { merchant: 'Highlands Coffee', categoryId: null });
    await tx(id, accountId, { merchant: 'Highlands Coffee Bar', categoryId: food.id });
    await tx(id, accountId, { merchant: 'Highlands Coffee', categoryId: coffee.id, type: 'income', amountMinor: 1000n });
    await tx(other.id, other.accountId, { merchant: 'Highlands Coffee', categoryId: other.coffee.id });
    expect(await repository.historyCategoryIds(id, { merchant: 'HIGHLANDS COFFEE', note: null }, 'expense', 10)).toEqual([coffee.id, food.id]);
    expect(await repository.historyCategoryIds(id, { merchant: 'Highlands Coffee', note: null }, 'expense', 1)).toEqual([coffee.id]);
    await tx(id, accountId, { notes: 'Ăn trưa', categoryId: food.id });
    expect(await repository.historyCategoryIds(id, { merchant: null, note: 'ăn  trưa' }, 'expense', 10)).toEqual([food.id]);
  });

  it('remembers one row per merchant and moves it on a new choice', async () => {
    const { id, coffee, food } = await setup();
    await repository.remember(id, ' Phở  Thìn ', food.id);
    await repository.remember(id, 'phở thìn', coffee.id);
    expect(await repository.rememberedCategoryId(id, 'phở thìn')).toBe(coffee.id);
    expect(await prisma.categorySuggestionMapping.findMany({ where: { userId: id }, select: { merchant: true } })).toEqual([{ merchant: 'phở thìn' }]);
    expect((await repository.categories(id)).map(c => c.iconToken).sort()).toEqual(['coffee', 'food']);
  });

  it('adds to the daily counter without a user column', async () => {
    const day = new Date('2001-01-01T00:00:00Z');
    await repository.count(day, 'entry', 'history', 'accepted');
    await repository.count(day, 'entry', 'history', 'accepted');
    await repository.count(day, 'entry', 'history', 'corrected');
    expect(await repository.stats(day, day)).toEqual([{ day: '2001-01-01', surface: 'entry', source: 'history', accepted: 2, corrected: 1 }]);
  });
});
