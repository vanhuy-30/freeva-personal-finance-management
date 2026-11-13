import { Inject, Injectable } from '@nestjs/common';
import { AppConfigReader } from './app-config.reader';
import {
  AppConfigError,
  effectiveValue,
  FLAG_OFF,
  isEditable,
  isFlagOn,
  parseConfigValue,
  parseFlagState,
  type ConfigValue,
  type FlagState,
} from './domain/app-config';
import {
  CONFIG_DEFINITIONS,
  crossCheckConfig,
  FLAG_DEFINITIONS,
  isConfigKey,
  isFlagKey,
  type ConfigKey,
  type FlagKey,
} from './domain/app-config-registry';
import {
  APP_CONFIG_REPOSITORY,
  type AppConfigRepository,
  type AppConfigSnapshot,
} from './domain/app-config.repository';

export type UserAppConfig = {
  version: number;
  flags: Record<string, boolean>;
  config: Record<string, ConfigValue>;
};

type LastChange = { updatedAt: string; updatedBy: string } | null;

@Injectable()
export class AppConfigService {
  constructor(
    @Inject(APP_CONFIG_REPOSITORY) private readonly repository: AppConfigRepository,
    private readonly reader: AppConfigReader,
  ) {}

  async forUser(userId: string): Promise<UserAppConfig> {
    const snapshot = await this.repository.snapshot();
    const flagRows = new Map(snapshot.flags.map((row) => [row.key, row]));
    const valueRows = new Map(snapshot.values.map((row) => [row.key, row]));
    const flags: Record<string, boolean> = {};
    for (const key of Object.keys(FLAG_DEFINITIONS)) {
      flags[key] = isFlagOn(key, flagRows.get(key) ?? FLAG_OFF, userId);
    }
    const config: Record<string, ConfigValue> = {};
    for (const [key, definition] of Object.entries(CONFIG_DEFINITIONS)) {
      config[key] = effectiveValue(definition, valueRows.get(key)).value;
    }
    return { version: snapshot.version, flags, config };
  }

  /** For API guards: whether `key` is on for this user right now. */
  async isEnabled(key: FlagKey, userId: string): Promise<boolean> {
    const snapshot = await this.repository.snapshot();
    const row = snapshot.flags.find((flag) => flag.key === key);
    return isFlagOn(key, row ?? FLAG_OFF, userId);
  }

  async forStaff() {
    return this.describe(await this.repository.snapshot());
  }

  async updateFlag(actorId: string, key: string, input: { enabled: unknown; userIds: unknown; percentage: unknown; version: number }) {
    if (!isFlagKey(key)) throw new AppConfigError('CONFIG_KEY_UNKNOWN');
    const state = parseFlagState(input);
    await this.repository.saveFlag({ key, state, expectedVersion: input.version, actorId });
    return this.forStaff();
  }

  async updateValue(actorId: string, key: string, input: { value: unknown; version: number }) {
    if (!isConfigKey(key)) throw new AppConfigError('CONFIG_KEY_UNKNOWN');
    const definition = CONFIG_DEFINITIONS[key];
    if (!isEditable(definition)) throw new AppConfigError('CONFIG_KEY_READONLY');
    const value = parseConfigValue(definition, input.value);
    await this.checkTogether(key, value);
    await this.repository.saveValue({ key, value, expectedVersion: input.version, actorId });
    this.reader.invalidate();
    return this.forStaff();
  }

  async resetValue(actorId: string, key: string, version: number) {
    if (!isConfigKey(key)) throw new AppConfigError('CONFIG_KEY_UNKNOWN');
    const definition = CONFIG_DEFINITIONS[key];
    if (!isEditable(definition)) throw new AppConfigError('CONFIG_KEY_READONLY');
    await this.checkTogether(key, definition.default);
    await this.repository.resetValue({ key, expectedVersion: version, actorId });
    this.reader.invalidate();
    return this.forStaff();
  }

  /** Cross-key rules on the values that would be live after this edit (fresh from the database). */
  private async checkTogether(key: ConfigKey, value: ConfigValue) {
    const snapshot = await this.repository.snapshot();
    const rows = new Map(snapshot.values.map((row) => [row.key, row]));
    const values = {} as Record<ConfigKey, ConfigValue>;
    for (const [other, definition] of Object.entries(CONFIG_DEFINITIONS) as [ConfigKey, (typeof CONFIG_DEFINITIONS)[ConfigKey]][]) {
      values[other] = other === key ? value : effectiveValue(definition, rows.get(other)).value;
    }
    const reason = crossCheckConfig(values);
    if (reason) throw new AppConfigError('CONFIG_VALUE_INVALID', reason);
  }

  private describe(snapshot: AppConfigSnapshot) {
    const flagRows = new Map(snapshot.flags.map((row) => [row.key, row]));
    const valueRows = new Map(snapshot.values.map((row) => [row.key, row]));
    const last = (row?: { updatedAt: Date; updatedBy: string }): LastChange =>
      (row ? { updatedAt: row.updatedAt.toISOString(), updatedBy: row.updatedBy } : null);
    return {
      version: snapshot.version,
      flags: Object.entries(FLAG_DEFINITIONS).map(([key, definition]) => {
        const row = flagRows.get(key);
        const state: FlagState = row ?? FLAG_OFF;
        return {
          key,
          description: definition.description,
          enabled: state.enabled,
          userIds: [...state.userIds],
          percentage: state.percentage,
          version: row?.version ?? 0,
          lastChange: last(row),
        };
      }),
      config: Object.entries(CONFIG_DEFINITIONS).map(([key, definition]) => {
        const row = valueRows.get(key);
        const { value, valid } = effectiveValue(definition, row);
        return {
          key,
          definition,
          value,
          isDefault: !row || !valid,
          version: row?.version ?? 0,
          lastChange: last(row),
        };
      }),
    };
  }
}
