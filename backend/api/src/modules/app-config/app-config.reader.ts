import { Inject, Injectable } from '@nestjs/common';
import { effectiveValue, type ConfigValue } from './domain/app-config';
import { CONFIG_DEFINITIONS, type ConfigKey, type ConfigValueOf } from './domain/app-config-registry';
import { APP_CONFIG_REPOSITORY, type AppConfigRepository } from './domain/app-config.repository';

/**
 * BE-P5-001: effective config values for business code (budgets, import, auth…), so the API
 * enforces what staff set. Reads are cached in process for [TTL_MS]; a staff save in this
 * process clears the cache, other instances catch up within the TTL.
 */
@Injectable()
export class AppConfigReader {
  static readonly TTL_MS = 30_000;

  private cache: { at: number; version: number; values: Record<ConfigKey, ConfigValue> } | null = null;

  /** Replaced in tests. */
  clock: () => number = Date.now;

  constructor(@Inject(APP_CONFIG_REPOSITORY) private readonly repository: AppConfigRepository) {}

  async value<K extends ConfigKey>(key: K): Promise<ConfigValueOf<K>> {
    return (await this.values())[key] as ConfigValueOf<K>;
  }

  async values(): Promise<Record<ConfigKey, ConfigValue>> {
    return (await this.load()).values;
  }

  /**
   * Config values for anyone, signed in or not (`GET /api/v1/app-config/public`): product
   * numbers only, no flags and nothing about a user, so sign-up screens can show the rules.
   */
  async published(): Promise<{ version: number; config: Record<ConfigKey, ConfigValue> }> {
    const { version, values } = await this.load();
    return { version, config: values };
  }

  private async load() {
    const cached = this.cache;
    if (cached && this.clock() - cached.at < AppConfigReader.TTL_MS) return cached;
    const snapshot = await this.repository.snapshot();
    const rows = new Map(snapshot.values.map((row) => [row.key, row]));
    const values = {} as Record<ConfigKey, ConfigValue>;
    for (const [key, definition] of Object.entries(CONFIG_DEFINITIONS) as [ConfigKey, (typeof CONFIG_DEFINITIONS)[ConfigKey]][]) {
      values[key] = effectiveValue(definition, rows.get(key)).value;
    }
    this.cache = { at: this.clock(), version: snapshot.version, values };
    return this.cache;
  }

  invalidate(): void {
    this.cache = null;
  }
}
