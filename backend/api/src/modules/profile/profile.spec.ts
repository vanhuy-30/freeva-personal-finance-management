import { AppConfigReader } from '../app-config/app-config.reader';
import { appConfigReaderFor } from '../app-config/testing';
import { Test } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { AuthGuard } from '../auth/auth.guard';
import { AuthService } from '../auth/auth.service';
import type { DeclaredIncomeBand } from './domain/declared-income';
import { PROFILE_REPOSITORY, declaredIncomeView, type Profile, type ProfileUpdate } from './domain/profile.repository';
import { ProfileController } from './profile.controller';
import { ProfileService } from './profile.service';
const initial: Profile = { displayName: null, locale: 'vi', defaultCurrencyCode: 'VND', timezone: 'Asia/Ho_Chi_Minh', fiscalMonthStartDay: 1, version: 1, goals: [],
  declaredIncome: null, displayCurrencyCode: null, autoSuggestEnabled: true, avatarUpdatedAt: null };
describe('MOB-P1-002 profile HTTP contract', () => {
  let app: INestApplication; let base: string;
  const profiles = new Map<string, Profile>();
  const avatars = new Map<string, Buffer>();
  const repo = {
    find: jest.fn(async (id: string) => profiles.get(id) ?? null),
    currencies: async () => [{ code: 'VND', minorDigits: 0, symbol: '₫', isDefault: true }, { code: 'USD', minorDigits: 2, symbol: null, isDefault: false }],
    saveOnboarding: jest.fn(async (id: string) => profiles.has(id)),
    saveDeclaredIncome: jest.fn(async (id: string, band: DeclaredIncomeBand | null) => {
      if (!profiles.has(id)) return false;
      profiles.set(id, { ...profiles.get(id)!, declaredIncome: declaredIncomeView(band) }); return true;
    }),
    saveAutoSuggest: jest.fn(async (id: string, enabled: boolean) => {
      if (!profiles.has(id)) return false;
      profiles.set(id, { ...profiles.get(id)!, autoSuggestEnabled: enabled }); return true;
    }),
    saveDisplayCurrency: jest.fn(async (id: string, code: string | null) => {
      if (!profiles.has(id)) return false;
      profiles.set(id, { ...profiles.get(id)!, displayCurrencyCode: code }); return true;
    }),
    saveAvatar: jest.fn(async (id: string, image: Buffer) => {
      if (!profiles.has(id)) return false;
      avatars.set(id, image); profiles.set(id, { ...profiles.get(id)!, avatarUpdatedAt: '2026-11-24T00:00:00.000Z' }); return true;
    }),
    readAvatar: jest.fn(async (id: string) => (avatars.has(id) ? { image: avatars.get(id)!, updatedAt: new Date('2026-11-24T00:00:00.000Z') } : null)),
    deleteAvatar: jest.fn(async (id: string) => { avatars.delete(id); profiles.set(id, { ...profiles.get(id)!, avatarUpdatedAt: null }); }),
    update: jest.fn(async (id: string, profile: ProfileUpdate) => {
      if (profiles.get(id)?.version !== profile.version) return null;
      const stored = profiles.get(id)!;
      const saved = { ...stored, ...profile, displayName: profile.displayName === undefined ? stored.displayName : profile.displayName, version: profile.version + 1 };
      profiles.set(id, saved); return saved;
    }),
  };
  beforeAll(async () => {
    const module = await Test.createTestingModule({ controllers: [ProfileController], providers: [ProfileService, AuthGuard,
      { provide: PROFILE_REPOSITORY, useValue: repo },
      { provide: AppConfigReader, useValue: appConfigReaderFor() },
      { provide: AuthService, useValue: { authenticate: async (token: string) => ({ userId: token[0] === 'a' ? 'owner' : 'other' }) } },
    ] }).compile();
    app = module.createNestApplication(); app.setGlobalPrefix('api');
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));
    await app.listen(0, '127.0.0.1'); base = await app.getUrl();
  });
  beforeEach(() => { profiles.set('owner', { ...initial }); profiles.set('other', { ...initial }); avatars.clear(); repo.update.mockClear(); repo.saveAvatar.mockClear(); });
  afterAll(async () => app?.close());
  async function request(method = 'GET', body?: object, token: string | null = 'a'.repeat(64), path = 'profile') {
    const result = await fetch(`${base}/api/v1/${path}`, { method,
      headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
      body: body ? JSON.stringify(body) : undefined });
    return { status: result.status, body: await result.text().then(text => (text ? JSON.parse(text) : null)), headers: result.headers };
  }
  describe('avatar', () => {
    const jpeg = Buffer.from([0xff, 0xd8, 0xff, 0xe0, 1, 2, 3, 4]);
    const put = (image: Buffer, token: string | null = 'a'.repeat(64)) => request('PUT', { imageBase64: image.toString('base64') }, token, 'profile/avatar');
    const get = (token = 'a'.repeat(64)) => fetch(`${base}/api/v1/profile/avatar`, { headers: { Authorization: `Bearer ${token}` } });
    it('stores a JPEG, serves it back to its owner only and reports when it changed', async () => {
      expect((await put(jpeg, null)).status).toBe(401);
      expect((await get('b'.repeat(64))).status).toBe(404);
      const saved = await fetch(`${base}/api/v1/profile/avatar`, { method: 'PUT', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${'a'.repeat(64)}` }, body: JSON.stringify({ imageBase64: jpeg.toString('base64') }) });
      expect(saved.status).toBe(204);
      const photo = await get();
      expect(photo.status).toBe(200);
      expect(await photo.json()).toEqual({ imageBase64: jpeg.toString('base64'), updatedAt: '2026-11-24T00:00:00.000Z' });
      expect((await get('b'.repeat(64))).status).toBe(404);
      expect((await request()).body.avatarUpdatedAt).toBe('2026-11-24T00:00:00.000Z');
    });
    it('refuses what is not a JPEG, is too large or is not base64', async () => {
      expect((await put(Buffer.from('GIF89a-not-a-jpeg'))).status).toBe(400);
      expect((await put(Buffer.concat([jpeg, Buffer.alloc(65536)]))).status).toBe(400);
      expect((await request('PUT', { imageBase64: 'not base64!' }, 'a'.repeat(64), 'profile/avatar')).status).toBe(400);
      expect((await request('PUT', {}, 'a'.repeat(64), 'profile/avatar')).status).toBe(400);
      expect(repo.saveAvatar).not.toHaveBeenCalledWith('owner', expect.anything());
    });
    it('removes the photo', async () => {
      await put(jpeg);
      const removed = await fetch(`${base}/api/v1/profile/avatar`, { method: 'DELETE', headers: { Authorization: `Bearer ${'a'.repeat(64)}` } });
      expect(removed.status).toBe(204);
      expect((await get()).status).toBe(404);
      expect((await request()).body.avatarUpdatedAt).toBeNull();
    });
  });
  it('requires auth and returns only own preferences without PII', async () => {
    expect((await request('GET', undefined, null)).status).toBe(401);
    const result = await request(); expect(result.body).toEqual(initial);
    expect(result.headers.get('cache-control')).toBe('no-store');
  });
  it('persists four fields for session owner and rejects stale version', async () => {
    const { goals, declaredIncome, displayCurrencyCode, autoSuggestEnabled, avatarUpdatedAt, ...editable } = initial;
    const changes = { ...editable, locale: 'en', defaultCurrencyCode: 'USD', timezone: 'America/New_York', fiscalMonthStartDay: 28 };
    expect((await request('PUT', changes)).body).toEqual({ ...changes, goals, declaredIncome, displayCurrencyCode, autoSuggestEnabled, avatarUpdatedAt, version: 2 });
    expect((await request()).body).toEqual({ ...changes, goals, declaredIncome, displayCurrencyCode, autoSuggestEnabled, avatarUpdatedAt, version: 2 });
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
  it('keeps displayName when omitted, trims it, and clears it when blank', async () => {
    const { displayName: _omit, goals: _goals, declaredIncome: _i, displayCurrencyCode: _d, autoSuggestEnabled: _a, avatarUpdatedAt: _av, ...rest } = initial;
    expect((await request('PUT', { ...rest, displayName: '  Minh  ' })).body.displayName).toBe('Minh');
    expect((await request('PUT', { ...rest, version: 2 })).body.displayName).toBe('Minh');
    expect((await request('PUT', { ...rest, version: 3, displayName: '   ' })).body.displayName).toBeNull();
    const long = await request('PUT', { ...rest, version: 4, displayName: 'x'.repeat(61) });
    expect(long.status).toBe(400);
  });
  it('supplies currency catalog and IANA timezones', async () => {
    const result = await request('GET', undefined, 'a'.repeat(64), 'profile/options');
    expect(result.body.currencies).toContainEqual({ code: 'USD', minorDigits: 2, symbol: null, isDefault: false });
    expect(result.body.currencies).toContainEqual({ code: 'VND', minorDigits: 0, symbol: '₫', isDefault: true });
    expect(result.body.timezones).toEqual(expect.arrayContaining(['UTC', 'Asia/Ho_Chi_Minh', 'America/New_York']));
  });
  it('DS-P2-004 stores onboarding answers, all optional, and rejects anything else', async () => {
    const send = (body: object, token: string | null = 'a'.repeat(64)) => fetch(`${base}/api/v1/profile/onboarding`, {
      method: 'PATCH', headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) }, body: JSON.stringify(body) });
    expect((await send({}, null)).status).toBe(401);
    expect((await send({ goals: ['save', 'budget'], declaredIncome: { minMinor: '10000000', maxMinor: '20000000' } })).status).toBe(204);
    expect(repo.saveOnboarding).toHaveBeenLastCalledWith('owner',
      { goals: ['save', 'budget'], declaredIncome: { minMinor: 10_000_000n, maxMinor: 20_000_000n } });
    expect((await send({ declaredIncome: { minMinor: '40000000', maxMinor: null } })).status).toBe(204);
    expect(repo.saveOnboarding).toHaveBeenLastCalledWith('owner', { declaredIncome: { minMinor: 40_000_000n, maxMinor: null } });
    expect((await send({ declaredIncome: { minMinor: '0', maxMinor: '5000000' } })).status).toBe(204);
    expect((await send({ goals: [] })).status).toBe(204);
    expect(repo.saveOnboarding).toHaveBeenLastCalledWith('owner', { goals: [] });
    // BE-P6-002: six goals, all allowed at once (config `onboarding.maxGoals` defaults to 6).
    expect((await send({ goals: ['track', 'budget', 'save', 'debt', 'assets', 'habits'] })).status).toBe(204);
    const calls = repo.saveOnboarding.mock.calls.length;
    for (const bad of [{ goals: ['save', 'save'] }, { goals: ['x'] }, { goals: ['emergency'] }, { goals: ['track', 'budget', 'save', 'debt', 'assets', 'habits', 'x'] },
      { trackingHabit: 'app' }, { monthlyIncomeMinor: '15000000' }, { reviewCadence: 'weekly' }, { email: 'a@b.test' },
      { declaredIncome: { minMinor: '0', maxMinor: null } }, { declaredIncome: { minMinor: '20', maxMinor: '10' } },
      { declaredIncome: { minMinor: '-5', maxMinor: '10' } }, { declaredIncome: { minMinor: '1.5', maxMinor: '10' } },
      { declaredIncome: { minMinor: 5, maxMinor: '10' } }, { declaredIncome: { minMinor: '5' } }, { declaredIncome: { minMinor: '5', maxMinor: '0' } },
      { declaredIncome: { minMinor: '1234567890123456789', maxMinor: null } }, { declaredIncome: { minMinor: '5', maxMinor: '10', extra: 1 } },
      { declaredIncome: '15000000' }, { declaredIncome: null }]) {
      expect((await send(bad)).status).toBe(400);
    }
    expect(repo.saveOnboarding.mock.calls.length).toBe(calls);
  });
  it('PRD-P5-E01 switches automatic suggestions off and on, and rejects bad values', async () => {
    const send = (body: object, token: string | null = 'a'.repeat(64)) => fetch(`${base}/api/v1/profile/auto-suggest`, { method: 'PUT',
      headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) }, body: JSON.stringify(body) });
    expect((await request()).body.autoSuggestEnabled).toBe(true);
    expect((await send({ enabled: false }, null)).status).toBe(401);
    expect((await send({ enabled: false })).status).toBe(204);
    expect((await request()).body.autoSuggestEnabled).toBe(false);
    expect((await send({ enabled: true })).status).toBe(204);
    expect((await request()).body.autoSuggestEnabled).toBe(true);
    for (const bad of [{ enabled: 'false' }, { enabled: null }, {}, { enabled: true, extra: 1 }]) {
      expect((await send(bad)).status).toBe(400);
    }
  });
  it('BE-P6-002 sets, changes and clears the declared income band, and rejects bad values', async () => {
    const send = (body: object, token: string | null = 'a'.repeat(64)) => request('PUT', body, token, 'profile/declared-income');
    const put = (body: object) => fetch(`${base}/api/v1/profile/declared-income`, { method: 'PUT',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${'a'.repeat(64)}` }, body: JSON.stringify(body) });
    expect((await send({ declaredIncome: { minMinor: '1', maxMinor: null } }, null)).status).toBe(401);
    expect((await put({ declaredIncome: { minMinor: '10000000', maxMinor: '20000000' } })).status).toBe(204);
    expect((await request()).body.declaredIncome).toEqual({ minMinor: '10000000', maxMinor: '20000000', midpointMinor: '15000000' });
    expect((await request('GET', undefined, 'b'.repeat(64))).body.declaredIncome).toBeNull();
    expect((await put({ declaredIncome: { minMinor: '40000000', maxMinor: null } })).status).toBe(204);
    expect((await request()).body.declaredIncome).toEqual({ minMinor: '40000000', maxMinor: null, midpointMinor: '50000000' });
    expect((await put({ declaredIncome: { minMinor: '0', maxMinor: '5000000' } })).status).toBe(204);
    expect((await request()).body.declaredIncome).toEqual({ minMinor: '0', maxMinor: '5000000', midpointMinor: '2500000' });
    expect((await put({ declaredIncome: null })).status).toBe(204);
    expect((await request()).body.declaredIncome).toBeNull();
    for (const bad of [{ declaredIncome: { minMinor: '0', maxMinor: null } }, { declaredIncome: { minMinor: '10', maxMinor: '9' } },
      { declaredIncome: { minMinor: '-1', maxMinor: '5' } }, { declaredIncome: { minMinor: '1.5', maxMinor: null } },
      { declaredIncome: { minMinor: 5, maxMinor: null } }, { declaredIncome: { maxMinor: '5' } }, { monthlyIncomeMinor: '1' }, {}]) {
      expect((await send(bad)).status).toBe(400);
    }
  });
  it('BE-P2-013 stores the display currency, null goes back to default, and rejects unknown codes', async () => {
    const send = (body: object, token: string | null = 'a'.repeat(64)) => request('PUT', body, token, 'profile/display-currency');
    expect((await send({ currencyCode: 'USD' }, null)).status).toBe(401);
    const saved = await fetch(`${base}/api/v1/profile/display-currency`, { method: 'PUT',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${'a'.repeat(64)}` }, body: JSON.stringify({ currencyCode: 'USD' }) });
    expect(saved.status).toBe(204);
    expect((await request()).body.displayCurrencyCode).toBe('USD');
    expect((await request('GET', undefined, 'b'.repeat(64))).body.displayCurrencyCode).toBeNull();
    await fetch(`${base}/api/v1/profile/display-currency`, { method: 'PUT',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${'a'.repeat(64)}` }, body: JSON.stringify({ currencyCode: null }) });
    expect((await request()).body.displayCurrencyCode).toBeNull();
    for (const bad of [{ currencyCode: 'XXX' }, { currencyCode: 'usd' }, { currencyCode: 5 }, {}, { currencyCode: 'USD', userId: 'other' }]) {
      expect((await send(bad)).status).toBe(400);
    }
  });
  it('BE-P2-012 returns saved answers on GET and keeps the budget number when the currency changes', async () => {
    const band = { minMinor: '10000000', maxMinor: '20000000', midpointMinor: '15000000' };
    profiles.set('owner', { ...initial, goals: ['save'], declaredIncome: band });
    const { goals, declaredIncome, displayCurrencyCode, autoSuggestEnabled, avatarUpdatedAt, ...editable } = initial;
    const saved = await request('PUT', { ...editable, defaultCurrencyCode: 'USD' });
    expect(saved.body).toMatchObject({ defaultCurrencyCode: 'USD', goals: ['save'], declaredIncome: band });
    expect((await request()).body.declaredIncome).toEqual(band);
    expect((await request('GET', undefined, 'b'.repeat(64))).body.declaredIncome).toBeNull();
  });
});
