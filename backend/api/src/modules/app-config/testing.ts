import { AppConfigReader } from './app-config.reader';
import type { ConfigValue } from './domain/app-config';
import type { ConfigKey } from './domain/app-config-registry';

/** Unit-test reader: code defaults plus `overrides`, no database. */
export function appConfigReaderFor(overrides: Partial<Record<ConfigKey, ConfigValue>> = {}): AppConfigReader {
  const at = new Date(0);
  return new AppConfigReader({
    snapshot: async () => ({
      version: 1,
      flags: [],
      values: Object.entries(overrides).map(([key, value]) => ({ key, value, version: 1, updatedAt: at, updatedBy: 'test' })),
    }),
    saveFlag: async () => { throw new Error('not in unit tests'); },
    saveValue: async () => { throw new Error('not in unit tests'); },
    resetValue: async () => { throw new Error('not in unit tests'); },
  });
}
