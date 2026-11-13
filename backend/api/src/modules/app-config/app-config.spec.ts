import { randomUUID } from 'node:crypto';
import { ForbiddenException, type ExecutionContext } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AppConfigReader } from './app-config.reader';
import { AppConfigService } from './app-config.service';
import {
  AppConfigError,
  FLAG_OFF,
  KEY_PATTERN,
  isFlagOn,
  parseConfigValue,
  parseFlagState,
  rolloutBucket,
  type ConfigDefinition,
} from './domain/app-config';
import { CONFIG_DEFINITIONS, crossCheckConfig, FLAG_DEFINITIONS } from './domain/app-config-registry';
import type { AppConfigRepository, AppConfigSnapshot } from './domain/app-config.repository';
import { FeatureGuard, RequireFeature } from './feature.guard';

function invalid(run: () => unknown): void {
  try {
    run();
  } catch (error) {
    expect(error).toBeInstanceOf(AppConfigError);
    expect((error as AppConfigError).code).toBe('CONFIG_VALUE_INVALID');
    return;
  }
  throw new Error('expected CONFIG_VALUE_INVALID');
}

describe('BE-P5-E08 config values', () => {
  const integer: ConfigDefinition = { type: 'integer', default: 4, min: 1, max: 4, description: '' };
  const list: ConfigDefinition = { type: 'integer_list', default: [80, 100], min: 1, max: 100, minItems: 1, maxItems: 4, description: '' };
  const money: ConfigDefinition = { type: 'money_minor_list', default: ['10'], currencyCode: 'VND', minItems: 0, maxItems: 3, description: '' };
  const one: ConfigDefinition = { type: 'enum', default: '6m', values: ['3m', '6m'], description: '' };
  const many: ConfigDefinition = { type: 'enum_list', default: ['a'], values: ['a', 'b'], minItems: 1, maxItems: 2, description: '' };
  const time: ConfigDefinition = { type: 'time', default: '21:00', description: '' };

  it('accepts values that fit', () => {
    expect(parseConfigValue(integer, 3)).toBe(3);
    expect(parseConfigValue(list, [70, 80, 100])).toEqual([70, 80, 100]);
    expect(parseConfigValue(money, ['5000', '99999999999999999'])).toEqual(['5000', '99999999999999999']);
    expect(parseConfigValue(money, [])).toEqual([]);
    expect(parseConfigValue(one, '3m')).toBe('3m');
    expect(parseConfigValue(many, ['b', 'a'])).toEqual(['b', 'a']);
    expect(parseConfigValue(time, '00:00')).toBe('00:00');
    expect(parseConfigValue(time, '23:59')).toBe('23:59');
  });

  it('BE-P5-E03 pair lists keep "text: value", reject unknown values and duplicates ignoring accents', () => {
    const pairs: ConfigDefinition = { type: 'pair_list', default: [], values: ['food', 'transport'], minItems: 0, maxItems: 3, maxTextLength: 10, description: '' };
    expect(parseConfigValue(pairs, [' Grab :transport', 'Phở Thìn: food'])).toEqual(['Grab: transport', 'Phở Thìn: food']);
    expect(parseConfigValue(pairs, ['a:b:food'])).toEqual(['a:b: food']);
    invalid(() => parseConfigValue(pairs, ['Grab transport']));
    invalid(() => parseConfigValue(pairs, ['Grab: bus']));
    invalid(() => parseConfigValue(pairs, ['Pho: food', 'phở: food']));
    invalid(() => parseConfigValue(pairs, ['Very long merchant: food']));
    invalid(() => parseConfigValue(pairs, ['a: food', 'b: food', 'c: food', 'd: food']));
    invalid(() => parseConfigValue(pairs, 'Grab: transport'));
  });

  it('rejects wrong types and out-of-range values', () => {
    invalid(() => parseConfigValue(integer, 5));
    invalid(() => parseConfigValue(integer, 0));
    invalid(() => parseConfigValue(integer, 2.5));
    invalid(() => parseConfigValue(integer, '3'));
    invalid(() => parseConfigValue(list, [80, 80]));
    invalid(() => parseConfigValue(list, [100, 80]));
    invalid(() => parseConfigValue(list, [0, 80]));
    invalid(() => parseConfigValue(list, [10, 20, 30, 40, 50]));
    invalid(() => parseConfigValue(list, []));
    invalid(() => parseConfigValue(list, 80));
    invalid(() => parseConfigValue(money, ['0']));
    invalid(() => parseConfigValue(money, ['-5']));
    invalid(() => parseConfigValue(money, ['1.5']));
    invalid(() => parseConfigValue(money, [10]));
    invalid(() => parseConfigValue(money, ['20', '10']));
    invalid(() => parseConfigValue(one, '1y'));
    invalid(() => parseConfigValue(many, ['a', 'a']));
    invalid(() => parseConfigValue(many, ['c']));
    invalid(() => parseConfigValue(many, []));
    invalid(() => parseConfigValue(time, '24:00'));
    invalid(() => parseConfigValue(time, '9:00'));
    invalid(() => parseConfigValue(time, null));
  });

  it('checks staff input for flags', () => {
    const id = randomUUID();
    expect(parseFlagState({ enabled: true, userIds: [id.toUpperCase(), id], percentage: 10 }))
      .toEqual({ enabled: true, userIds: [id], percentage: 10 });
    invalid(() => parseFlagState({ enabled: 'yes', userIds: [], percentage: 0 }));
    invalid(() => parseFlagState({ enabled: true, userIds: ['not-a-uuid'], percentage: 0 }));
    invalid(() => parseFlagState({ enabled: true, userIds: [], percentage: 101 }));
    invalid(() => parseFlagState({ enabled: true, userIds: [], percentage: -1 }));
  });
});

describe('BE-P5-E08 registry', () => {
  it('every default fits its own definition and every key is well formed', () => {
    for (const [key, definition] of Object.entries(CONFIG_DEFINITIONS)) {
      expect(KEY_PATTERN.test(key)).toBe(true);
      expect(parseConfigValue(definition, definition.default)).toEqual(definition.default);
    }
    for (const key of Object.keys(FLAG_DEFINITIONS)) expect(KEY_PATTERN.test(key)).toBe(true);
  });

  it('keeps the values the app uses today', () => {
    expect(CONFIG_DEFINITIONS['budget.defaultAlertThresholds'].default).toEqual([80, 100]);
    expect(CONFIG_DEFINITIONS['notification.dailyLogDefaultTime'].default).toBe('21:00');
    expect(CONFIG_DEFINITIONS['profile.displayNameMaxLength'].default).toBe(60);
    expect(CONFIG_DEFINITIONS['import.maxRows'].default).toBe(2000);
  });
});

describe('BE-P5-E08 flag evaluation', () => {
  const user = '5f0c1a52-8a1e-4f4c-9b7e-3c8f2e6d1a90';

  it('is off when disabled, even for listed users', () => {
    expect(isFlagOn('insights', FLAG_OFF, user)).toBe(false);
    expect(isFlagOn('insights', { enabled: false, userIds: [user], percentage: 100 }, user)).toBe(false);
  });

  it('turns on for listed users and at 100%, off at 0%', () => {
    expect(isFlagOn('insights', { enabled: true, userIds: [user], percentage: 0 }, user.toUpperCase())).toBe(true);
    expect(isFlagOn('insights', { enabled: true, userIds: [], percentage: 100 }, user)).toBe(true);
    expect(isFlagOn('insights', { enabled: true, userIds: [], percentage: 0 }, user)).toBe(false);
  });

  it('gives a user the same bucket every time and spreads users evenly', () => {
    expect(rolloutBucket('insights', user)).toBe(rolloutBucket('insights', user));
    const state = { enabled: true, userIds: [], percentage: 30 };
    let on = 0;
    for (let i = 0; i < 10_000; i += 1) if (isFlagOn('insights', state, randomUUID())) on += 1;
    expect(on).toBeGreaterThan(2_700);
    expect(on).toBeLessThan(3_300);
  });
});

describe('BE-P5-E08 service', () => {
  const user = randomUUID();
  const staff = randomUUID();
  const snapshot = (overrides: Partial<AppConfigSnapshot> = {}): AppConfigSnapshot => ({ version: 1, flags: [], values: [], ...overrides });
  let repository: jest.Mocked<AppConfigRepository>;
  let service: AppConfigService;

  beforeEach(() => {
    repository = {
      snapshot: jest.fn().mockResolvedValue(snapshot()),
      saveFlag: jest.fn(),
      saveValue: jest.fn(),
      resetValue: jest.fn(),
    };
    service = new AppConfigService(repository, new AppConfigReader(repository));
  });

  it('returns defaults and every flag off on an empty store', async () => {
    const config = await service.forUser(user);
    expect(config.version).toBe(1);
    expect(Object.values(config.flags).every((on) => on === false)).toBe(true);
    expect(Object.keys(config.flags)).toEqual(Object.keys(FLAG_DEFINITIONS));
    expect(config.config['forecast.monthOptions']).toEqual([3, 6, 12]);
  });

  it('uses stored values and falls back to the default when a stored value no longer fits', async () => {
    const at = new Date();
    repository.snapshot.mockResolvedValue(snapshot({
      version: 7,
      flags: [{ key: 'insights', enabled: true, userIds: [user], percentage: 0, version: 2, updatedAt: at, updatedBy: staff }],
      values: [
        { key: 'report.topRows', value: 5, version: 1, updatedAt: at, updatedBy: staff },
        { key: 'home.recentTransactions', value: 999, version: 1, updatedAt: at, updatedBy: staff },
      ],
    }));
    const config = await service.forUser(user);
    expect(config.version).toBe(7);
    expect(config.flags.insights).toBe(true);
    expect(config.config['report.topRows']).toBe(5);
    expect(config.config['home.recentTransactions']).toBe(3);
  });

  it('rejects unknown keys and bad values before writing', async () => {
    await expect(service.updateValue(staff, 'nope', { value: 1, version: 0 })).rejects.toMatchObject({ code: 'CONFIG_KEY_UNKNOWN' });
    await expect(service.updateFlag(staff, 'nope', { enabled: true, userIds: [], percentage: 0, version: 0 })).rejects.toMatchObject({ code: 'CONFIG_KEY_UNKNOWN' });
    await expect(service.updateValue(staff, 'report.topRows', { value: 0, version: 0 })).rejects.toMatchObject({ code: 'CONFIG_VALUE_INVALID' });
    expect(repository.saveValue).not.toHaveBeenCalled();
    expect(repository.saveFlag).not.toHaveBeenCalled();
  });

  it('does not report success when the audited write fails', async () => {
    repository.saveValue.mockRejectedValue(new Error('audit insert failed'));
    await expect(service.updateValue(staff, 'report.topRows', { value: 4, version: 0 })).rejects.toThrow('audit insert failed');
  });

  it('passes the checked value and staff actor to the repository', async () => {
    await service.updateValue(staff, 'onboarding.goalKinds', { value: ['home', 'car'], version: 3 });
    expect(repository.saveValue).toHaveBeenCalledWith({ key: 'onboarding.goalKinds', value: ['home', 'car'], expectedVersion: 3, actorId: staff });
  });
});

describe('BE-P5-E08 FeatureGuard', () => {
  class Routes {
    @RequireFeature('insights') guarded() {}
    open() {}
  }
  const context = (handler: () => void): ExecutionContext => ({
    getHandler: () => handler,
    getClass: () => Routes,
    switchToHttp: () => ({ getRequest: () => ({ session: { userId: 'u1' } }) }),
  }) as unknown as ExecutionContext;

  it('lets unmarked routes through and blocks marked routes while the flag is off', async () => {
    const appConfig = { isEnabled: jest.fn().mockResolvedValue(false) } as unknown as AppConfigService;
    const guard = new FeatureGuard(new Reflector(), appConfig);
    await expect(guard.canActivate(context(Routes.prototype.open))).resolves.toBe(true);
    await expect(guard.canActivate(context(Routes.prototype.guarded))).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('allows marked routes when the flag is on', async () => {
    const appConfig = { isEnabled: jest.fn().mockResolvedValue(true) } as unknown as AppConfigService;
    const guard = new FeatureGuard(new Reflector(), appConfig);
    await expect(guard.canActivate(context(Routes.prototype.guarded))).resolves.toBe(true);
    expect(appConfig.isEnabled).toHaveBeenCalledWith('insights', 'u1');
  });
});

describe('BE-P5-001 reader', () => {
  const at = new Date();
  const stored = (values: { key: string; value: unknown }[]): AppConfigRepository => ({
    snapshot: jest.fn().mockResolvedValue({
      version: 2, flags: [], values: values.map((row) => ({ ...row, version: 1, updatedAt: at, updatedBy: 's' })),
    }),
    saveFlag: jest.fn(),
    saveValue: jest.fn(),
    resetValue: jest.fn(),
  });

  it('returns staff values, defaults, and ignores a stored value on a read-only key', async () => {
    const reader = new AppConfigReader(stored([
      { key: 'import.maxRows', value: 500 },
      { key: 'limit.passwordMaxLength', value: 64 },
    ]));
    expect(await reader.value('import.maxRows')).toBe(500);
    expect(await reader.value('limit.passwordMaxLength')).toBe(128);
    expect(await reader.value('budget.defaultAlertThresholds')).toEqual([80, 100]);
  });

  it('publishes values with the version and no flags', async () => {
    const reader = new AppConfigReader(stored([{ key: 'report.topRows', value: 5 }]));
    const published = await reader.published();
    expect(published.version).toBe(2);
    expect(published.config['report.topRows']).toBe(5);
    expect(published).not.toHaveProperty('flags');
  });

  it('caches for the TTL and reloads after invalidate or expiry', async () => {
    const repository = stored([]);
    const reader = new AppConfigReader(repository);
    let now = 1_000;
    reader.clock = () => now;
    await reader.value('report.topRows');
    await reader.value('home.recentTransactions');
    expect(repository.snapshot).toHaveBeenCalledTimes(1);
    now += AppConfigReader.TTL_MS;
    await reader.value('report.topRows');
    expect(repository.snapshot).toHaveBeenCalledTimes(2);
    reader.invalidate();
    await reader.value('report.topRows');
    expect(repository.snapshot).toHaveBeenCalledTimes(3);
  });
});

describe('BE-P5-001 staff edits', () => {
  const staff = randomUUID();
  let repository: jest.Mocked<AppConfigRepository>;
  let reader: AppConfigReader;
  let service: AppConfigService;

  beforeEach(() => {
    repository = {
      snapshot: jest.fn().mockResolvedValue({ version: 1, flags: [], values: [] }),
      saveFlag: jest.fn(),
      saveValue: jest.fn(),
      resetValue: jest.fn(),
    };
    reader = new AppConfigReader(repository);
    service = new AppConfigService(repository, reader);
  });

  it('refuses to edit or reset a read-only limit', async () => {
    await expect(service.updateValue(staff, 'limit.passwordMaxLength', { value: 128, version: 0 }))
      .rejects.toMatchObject({ code: 'CONFIG_KEY_READONLY' });
    await expect(service.resetValue(staff, 'limit.passwordMaxLength', 1)).rejects.toMatchObject({ code: 'CONFIG_KEY_READONLY' });
    expect(repository.saveValue).not.toHaveBeenCalled();
  });

  it('rejects a value that breaks a rule across keys', async () => {
    await expect(service.updateValue(staff, 'installment.defaultTerm', { value: 24, version: 0 }))
      .rejects.toMatchObject({ code: 'CONFIG_VALUE_INVALID', reason: expect.stringContaining('installment.termOptions') });
    await expect(service.updateValue(staff, 'creditCard.highUsagePercent', { value: 95, version: 0 }))
      .rejects.toMatchObject({ code: 'CONFIG_VALUE_INVALID' });
    await expect(service.updateValue(staff, 'budget.maxAlertThresholds', { value: 1, version: 0 }))
      .rejects.toMatchObject({ code: 'CONFIG_VALUE_INVALID' });
    expect(repository.saveValue).not.toHaveBeenCalled();
  });

  it('checks the rule against values already saved', async () => {
    repository.snapshot.mockResolvedValue({
      version: 2, flags: [], values: [{ key: 'installment.termOptions', value: [6, 24], version: 1, updatedAt: new Date(), updatedBy: staff }],
    });
    await service.updateValue(staff, 'installment.defaultTerm', { value: 24, version: 0 });
    expect(repository.saveValue).toHaveBeenCalled();
  });

  it('clears the reader cache after a save', async () => {
    await reader.value('report.topRows');
    await service.updateValue(staff, 'report.topRows', { value: 5, version: 0 });
    repository.snapshot.mockResolvedValue({
      version: 2, flags: [], values: [{ key: 'report.topRows', value: 5, version: 1, updatedAt: new Date(), updatedBy: staff }],
    });
    expect(await reader.value('report.topRows')).toBe(5);
  });

  it('every default set passes the cross-key rules', () => {
    const defaults = Object.fromEntries(Object.entries(CONFIG_DEFINITIONS).map(([key, d]) => [key, d.default]));
    expect(crossCheckConfig(defaults as Parameters<typeof crossCheckConfig>[0])).toBeNull();
  });
});
