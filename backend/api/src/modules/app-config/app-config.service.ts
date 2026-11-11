import { Inject, Injectable } from '@nestjs/common';
import {
  AppConfigError,
  FLAG_OFF,
  isFlagOn,
  parseConfigValue,
  parseFlagState,
  type ConfigDefinition,
  type ConfigValue,
  type FlagState,
} from './domain/app-config';
import {
  CONFIG_DEFINITIONS,
  FLAG_DEFINITIONS,
  isConfigKey,
  isFlagKey,
  type FlagKey,
} from './domain/app-config-registry';
import {
  APP_CONFIG_REPOSITORY,
  type AppConfigRepository,
  type AppConfigSnapshot,
  type StoredValue,
} from './domain/app-config.repository';

export type UserAppConfig = {
  version: number;
  flags: Record<string, boolean>;
  config: Record<string, ConfigValue>;
};

type LastChange = { updatedAt: string; updatedBy: string } | null;

/** A stored value that no longer fits its definition (definition tightened later) falls back to the default. */
function effectiveValue(definition: ConfigDefinition, stored: StoredValue | undefined): { value: ConfigValue; valid: boolean } {
  if (!stored) return { value: definition.default, valid: true };
  try {
    return { value: parseConfigValue(definition, stored.value), valid: true };
  } catch {
    return { value: definition.default, valid: false };
  }
}

@Injectable()
export class AppConfigService {
  constructor(@Inject(APP_CONFIG_REPOSITORY) private readonly repository: AppConfigRepository) {}

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
    const value = parseConfigValue(CONFIG_DEFINITIONS[key], input.value);
    await this.repository.saveValue({ key, value, expectedVersion: input.version, actorId });
    return this.forStaff();
  }

  async resetValue(actorId: string, key: string, version: number) {
    if (!isConfigKey(key)) throw new AppConfigError('CONFIG_KEY_UNKNOWN');
    await this.repository.resetValue({ key, expectedVersion: version, actorId });
    return this.forStaff();
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
