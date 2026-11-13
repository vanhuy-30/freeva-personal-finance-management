import { AppConfigReader } from '../app-config/app-config.reader';
import { appConfigReaderFor } from '../app-config/testing';
import { Test } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { AuthGuard } from '../auth/auth.guard';
import { AuthService } from '../auth/auth.service';
import { PROFILE_REPOSITORY, type Profile, type ProfileUpdate } from './domain/profile.repository';
import { ProfileController } from './profile.controller';
import { ProfileService } from './profile.service';
const initial: Profile = { displayName: null, locale: 'vi', defaultCurrencyCode: 'VND', timezone: 'Asia/Ho_Chi_Minh', fiscalMonthStartDay: 1, version: 1, goals: [],
  monthlyIncomeMinor: null, displayCurrencyCode: null, autoSuggestEnabled: true };
describe('MOB-P1-002 profile HTTP contract', () => {
  let app: INestApplication; let base: string;
  const profiles = new Map<string, Profile>();
  const repo = {
    find: jest.fn(async (id: string) => profiles.get(id) ?? null),
    currencies: async () => [{ code: 'VND', minorDigits: 0, symbol: '₫', isDefault: true }, { code: 'USD', minorDigits: 2, symbol: null, isDefault: false }],
    saveOnboarding: jest.fn(async (id: string) => profiles.has(id)),
    saveMonthlyIncome: jest.fn(async (id: string, minor: string | null) => {
      if (!profiles.has(id)) return false;
      profiles.set(id, { ...profiles.get(id)!, monthlyIncomeMinor: minor }); return true;
    }),
    saveAutoSuggest: jest.fn(async (id: string, enabled: boolean) => {
      if (!profiles.has(id)) return false;
      profiles.set(id, { ...profiles.get(id)!, autoSuggestEnabled: enabled }); return true;
    }),
    saveDisplayCurrency: jest.fn(async (id: string, code: string | null) => {
      if (!profiles.has(id)) return false;
      profiles.set(id, { ...profiles.get(id)!, displayCurrencyCode: code }); return true;
    }),
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
    const { goals, monthlyIncomeMinor, displayCurrencyCode, autoSuggestEnabled, ...editable } = initial;
    const changes = { ...editable, locale: 'en', defaultCurrencyCode: 'USD', timezone: 'America/New_York', fiscalMonthStartDay: 28 };
    expect((await request('PUT', changes)).body).toEqual({ ...changes, goals, monthlyIncomeMinor, displayCurrencyCode, autoSuggestEnabled, version: 2 });
    expect((await request()).body).toEqual({ ...changes, goals, monthlyIncomeMinor, displayCurrencyCode, autoSuggestEnabled, version: 2 });
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
    const { displayName: _omit, goals: _goals, monthlyIncomeMinor: _i, displayCurrencyCode: _d, autoSuggestEnabled: _a, ...rest } = initial;
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
    expect((await send({ goals: ['save', 'budget'], monthlyIncomeMinor: '25000000' })).status).toBe(204);
    expect((await send({ monthlyIncomeMinor: '15000000' })).status).toBe(204);
    expect(repo.saveOnboarding).toHaveBeenLastCalledWith('owner', { monthlyIncomeMinor: '15000000' });
    expect((await send({ goals: [] })).status).toBe(204);
    expect(repo.saveOnboarding).toHaveBeenLastCalledWith('owner', { goals: [] });
    for (const bad of [{ goals: ['save', 'budget', 'debt'] }, { goals: ['save', 'save'] }, { goals: ['x'] },
      { goals: ['debt'] }, { goals: ['emergency'] }, { trackingHabit: 'app' }, { monthlyIncomeMinor: '0' }, { monthlyIncomeMinor: '-5' }, { monthlyIncomeMinor: '1.5' }, { monthlyIncomeMinor: 5000000 },
      { monthlyIncomeMinor: '1234567890123456789' }, { reviewCadence: 'weekly' }, { email: 'a@b.test' }]) {
      expect((await send(bad)).status).toBe(400);
    }
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
  it('BE-P3-012 sets, changes and clears the monthly income, and rejects bad values', async () => {
    const send = (body: object, token: string | null = 'a'.repeat(64)) => request('PUT', body, token, 'profile/monthly-income');
    const put = (body: object) => fetch(`${base}/api/v1/profile/monthly-income`, { method: 'PUT',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${'a'.repeat(64)}` }, body: JSON.stringify(body) });
    expect((await send({ monthlyIncomeMinor: '1' }, null)).status).toBe(401);
    expect((await put({ monthlyIncomeMinor: '20000000' })).status).toBe(204);
    expect((await request()).body.monthlyIncomeMinor).toBe('20000000');
    expect((await request('GET', undefined, 'b'.repeat(64))).body.monthlyIncomeMinor).toBeNull();
    expect((await put({ monthlyIncomeMinor: null })).status).toBe(204);
    expect((await request()).body.monthlyIncomeMinor).toBeNull();
    for (const bad of [{ monthlyIncomeMinor: '0' }, { monthlyIncomeMinor: '-1' }, { monthlyIncomeMinor: '1.5' }, { monthlyIncomeMinor: 5 }, {}]) {
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
    profiles.set('owner', { ...initial, goals: ['save'], monthlyIncomeMinor: '15000000' });
    const { goals, monthlyIncomeMinor, displayCurrencyCode, autoSuggestEnabled, ...editable } = initial;
    const saved = await request('PUT', { ...editable, defaultCurrencyCode: 'USD' });
    expect(saved.body).toMatchObject({ defaultCurrencyCode: 'USD', goals: ['save'], monthlyIncomeMinor: '15000000' });
    expect((await request()).body.monthlyIncomeMinor).toBe('15000000');
    expect((await request('GET', undefined, 'b'.repeat(64))).body.monthlyIncomeMinor).toBeNull();
  });
});
