import { randomUUID } from 'node:crypto';
import { PrismaService } from '../src/infrastructure/prisma/prisma.service';
import { PrismaProfileRepository } from '../src/modules/profile/infrastructure/prisma-profile.repository';

const databaseUrl = process.env.AUTH_TEST_DATABASE_URL;
if (!databaseUrl || new URL(databaseUrl).pathname !== '/auth_test') {
  throw new Error('AUTH_TEST_DATABASE_URL must point to an isolated database named auth_test');
}
process.env.DATABASE_URL = databaseUrl;

describe('profile avatar PostgreSQL', () => {
  const prisma = new PrismaService();
  const repository = new PrismaProfileRepository(prisma);
  const jpeg = Buffer.from([0xff, 0xd8, 0xff, 0xe0, 9, 8, 7]);
  let userId: string;

  beforeAll(async () => {
    await prisma.$connect();
    userId = (await prisma.user.create({ data: { email: `avatar-${randomUUID()}@example.test`, defaultCurrencyCode: 'VND' } })).id;
  });
  afterAll(async () => {
    await prisma.user.deleteMany({ where: { id: userId } });
    await prisma.$disconnect();
  });

  it('stores, replaces, reads and removes the photo and reports when it changed', async () => {
    expect((await repository.find(userId))?.avatarUpdatedAt).toBeNull();
    expect(await repository.readAvatar(userId)).toBeNull();
    expect(await repository.saveAvatar(userId, jpeg)).toBe(true);
    const first = await repository.find(userId);
    expect(first?.avatarUpdatedAt).toEqual(expect.any(String));
    expect((await repository.readAvatar(userId))?.image).toEqual(jpeg);
    const next = Buffer.from([0xff, 0xd8, 0xff, 1, 2]);
    expect(await repository.saveAvatar(userId, next)).toBe(true);
    expect((await repository.readAvatar(userId))?.image).toEqual(next);
    await repository.deleteAvatar(userId);
    expect(await repository.readAvatar(userId)).toBeNull();
    expect((await repository.find(userId))?.avatarUpdatedAt).toBeNull();
  });

  it('knows no photo for a missing user, refuses an empty or oversized one, and goes with the account', async () => {
    expect(await repository.saveAvatar(randomUUID(), jpeg)).toBe(false);
    await expect(repository.saveAvatar(userId, Buffer.alloc(0))).rejects.toThrow();
    await expect(repository.saveAvatar(userId, Buffer.alloc(65537, 1))).rejects.toThrow();
    await repository.saveAvatar(userId, jpeg);
    await prisma.user.delete({ where: { id: userId } });
    expect(await prisma.userAvatar.count({ where: { userId } })).toBe(0);
    userId = (await prisma.user.create({ data: { email: `avatar-${randomUUID()}@example.test`, defaultCurrencyCode: 'VND' } })).id;
  });
});
