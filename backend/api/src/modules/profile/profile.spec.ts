import { Test } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { AuthGuard } from '../auth/auth.guard';
import { AuthService } from '../auth/auth.service';
import { PROFILE_REPOSITORY, type Profile } from './domain/profile.repository';
import { ProfileController } from './profile.controller';
import { ProfileService } from './profile.service';
const initial: Profile = { locale: 'vi', defaultCurrencyCode: 'VND', timezone: 'Asia/Ho_Chi_Minh', fiscalMonthStartDay: 1, version: 1 };
describe('MOB-P1-002 profile HTTP contract', () => {
  let app: INestApplication; let base: string;
  const profiles = new Map<string, Profile>();
  const repo = {
    find: jest.fn(async (id: string) => profiles.get(id) ?? null),
    currencies: async () => [{ code: 'VND', minorDigits: 0 }, { code: 'USD', minorDigits: 2 }],
    update: jest.fn(async (id: string, profile: Profile) => {
      if (profiles.get(id)?.version !== profile.version) return null;
      const saved = { ...profile, version: profile.version + 1 }; profiles.set(id, saved); return saved;
    }),
  };
  beforeAll(async () => {
    const module = await Test.createTestingModule({ controllers: [ProfileController], providers: [ProfileService, AuthGuard,
      { provide: PROFILE_REPOSITORY, useValue: repo },
      { provide: AuthService, useValue: { authenticate: async (token: string) => ({ userId: token[0] === 'a' ? 'owner' : 'other' }) } },
    ] }).compile();
    app = module.createNestApplication(); app.setGlobalPrefix('api');
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));
    await app.listen(0, '127.0.0.1'); base = await app.getUrl();
  });
  beforeEach(() => { profiles.set('owner', { ...initial }); profiles.set('other', { ...initial }); repo.update.mockClear(); });
  afterAll(async () => app?.close());
  async function request(method = 'GET', body?: object, token: string | null = 'a'.repeat(64), path = 'profile') {
    const result = await fetch(`${base}/api/v1/${path}`, { method,
      headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
      body: body ? JSON.stringify(body) : undefined });
    return { status: result.status, body: await result.json(), headers: result.headers };
  }
  it('requires auth and returns only own preferences without PII', async () => {
    expect((await request('GET', undefined, null)).status).toBe(401);
    const result = await request(); expect(result.body).toEqual(initial);
    expect(result.headers.get('cache-control')).toBe('no-store');
  });
  it('persists four fields for session owner and rejects stale version', async () => {
    const changes = { ...initial, locale: 'en', defaultCurrencyCode: 'USD', timezone: 'America/New_York', fiscalMonthStartDay: 28 };
    expect((await request('PUT', changes)).body).toEqual({ ...changes, version: 2 });
    expect((await request()).body).toEqual({ ...changes, version: 2 });
    expect((await request('GET', undefined, 'b'.repeat(64))).body).toEqual(initial);
    expect((await request('PUT', changes)).status).toBe(409);
  });
  it.each([{ fiscalMonthStartDay: 0 }, { fiscalMonthStartDay: 29 }, { fiscalMonthStartDay: 1.5 },
    { fiscalMonthStartDay: '2' }, { timezone: '+07:00' }, { timezone: 'Asia/Imaginary' },
    { locale: 'fr' }, { defaultCurrencyCode: 'XXX' }, { version: 0 }, { version: '1' },
    { userId: 'other' }, { email: 'sensitive@example.test' }])('rejects invalid or foreign fields %j', async (fields) => {
      const result = await request('PUT', { ...initial, ...fields });
      expect(result.status).toBe(400); expect(result.body.error.code).toBe('VALIDATION_ERROR');
      expect(repo.update).not.toHaveBeenCalled();
      expect(JSON.stringify(result.body)).not.toContain('sensitive@example.test');
  });
  it('supplies currency catalog and IANA timezones', async () => {
    const result = await request('GET', undefined, 'a'.repeat(64), 'profile/options');
    expect(result.body.currencies).toContainEqual({ code: 'USD', minorDigits: 2 });
    expect(result.body.timezones).toEqual(expect.arrayContaining(['UTC', 'Asia/Ho_Chi_Minh', 'America/New_York']));
  });
});
