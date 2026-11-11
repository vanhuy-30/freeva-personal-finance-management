import { createHash } from 'node:crypto';

/** BE-P5-E08: flag and config definitions, value checks and flag evaluation. Pure. */

export type AppConfigErrorCode =
  | 'CONFIG_KEY_UNKNOWN'
  | 'CONFIG_VALUE_INVALID'
  | 'CONFIG_CONFLICT';

export class AppConfigError extends Error {
  constructor(readonly code: AppConfigErrorCode, readonly reason?: string) {
    super(code);
  }
}

type Base = { description: string };

export type IntegerDefinition = Base & { type: 'integer'; default: number; min: number; max: number };
/** Unique, ascending integers (option chips, thresholds). */
export type IntegerListDefinition = Base & {
  type: 'integer_list'; default: readonly number[]; min: number; max: number; minItems: number; maxItems: number;
};
/** Positive money amounts as minor-unit strings, unique and ascending. */
export type MoneyMinorListDefinition = Base & {
  type: 'money_minor_list'; default: readonly string[]; currencyCode: string; minItems: number; maxItems: number;
};
export type EnumDefinition = Base & { type: 'enum'; default: string; values: readonly string[] };
export type EnumListDefinition = Base & {
  type: 'enum_list'; default: readonly string[]; values: readonly string[]; minItems: number; maxItems: number;
};
/** Local time `HH:mm`. */
export type TimeDefinition = Base & { type: 'time'; default: string };

export type ConfigDefinition =
  | IntegerDefinition
  | IntegerListDefinition
  | MoneyMinorListDefinition
  | EnumDefinition
  | EnumListDefinition
  | TimeDefinition;

export type ConfigValue = number | string | readonly number[] | readonly string[];

export type FlagDefinition = { description: string };

export type FlagState = { enabled: boolean; userIds: readonly string[]; percentage: number };

export const FLAG_OFF: FlagState = { enabled: false, userIds: [], percentage: 0 };

export const KEY_PATTERN = /^[a-z][a-zA-Z0-9_]*(\.[a-z][a-zA-Z0-9]*)?$/;
export const FLAG_MAX_USER_IDS = 500;

const TIME_PATTERN = /^([01]\d|2[0-3]):[0-5]\d$/;
const MINOR_PATTERN = /^[1-9]\d{0,17}$/;

function fail(reason: string): never {
  throw new AppConfigError('CONFIG_VALUE_INVALID', reason);
}

function checkCount(length: number, minItems: number, maxItems: number): void {
  if (length < minItems || length > maxItems) fail(`must have ${minItems}-${maxItems} items`);
}

function checkAscending<T>(items: readonly T[], less: (a: T, b: T) => boolean): void {
  for (let i = 1; i < items.length; i += 1) {
    if (!less(items[i - 1], items[i])) fail('items must be unique and ascending');
  }
}

/** Returns a clean copy of `value` when it fits `definition`; throws `CONFIG_VALUE_INVALID` otherwise. */
export function parseConfigValue(definition: ConfigDefinition, value: unknown): ConfigValue {
  switch (definition.type) {
    case 'integer': {
      if (typeof value !== 'number' || !Number.isInteger(value)) fail('must be an integer');
      if (value < definition.min || value > definition.max) fail(`must be ${definition.min}-${definition.max}`);
      return value;
    }
    case 'integer_list': {
      if (!Array.isArray(value)) fail('must be a list of integers');
      checkCount(value.length, definition.minItems, definition.maxItems);
      for (const item of value) {
        if (typeof item !== 'number' || !Number.isInteger(item)) fail('must be a list of integers');
        if (item < definition.min || item > definition.max) fail(`items must be ${definition.min}-${definition.max}`);
      }
      const items = value as number[];
      checkAscending(items, (a, b) => a < b);
      return [...items];
    }
    case 'money_minor_list': {
      if (!Array.isArray(value)) fail('must be a list of minor-unit strings');
      checkCount(value.length, definition.minItems, definition.maxItems);
      for (const item of value) {
        if (typeof item !== 'string' || !MINOR_PATTERN.test(item)) fail('items must be positive minor-unit strings');
      }
      const items = value as string[];
      checkAscending(items, (a, b) => BigInt(a) < BigInt(b));
      return [...items];
    }
    case 'enum': {
      if (typeof value !== 'string' || !definition.values.includes(value)) fail(`must be one of ${definition.values.join(', ')}`);
      return value;
    }
    case 'enum_list': {
      if (!Array.isArray(value)) fail('must be a list');
      checkCount(value.length, definition.minItems, definition.maxItems);
      for (const item of value) {
        if (typeof item !== 'string' || !definition.values.includes(item)) fail(`items must be one of ${definition.values.join(', ')}`);
      }
      const items = value as string[];
      if (new Set(items).size !== items.length) fail('items must be unique');
      return [...items];
    }
    case 'time': {
      if (typeof value !== 'string' || !TIME_PATTERN.test(value)) fail('must be HH:mm');
      return value;
    }
  }
}

/** Validates staff input for a flag. */
export function parseFlagState(input: { enabled: unknown; userIds: unknown; percentage: unknown }): FlagState {
  if (typeof input.enabled !== 'boolean') fail('enabled must be a boolean');
  if (typeof input.percentage !== 'number' || !Number.isInteger(input.percentage) || input.percentage < 0 || input.percentage > 100) {
    fail('percentage must be 0-100');
  }
  if (!Array.isArray(input.userIds) || input.userIds.length > FLAG_MAX_USER_IDS) fail(`userIds must have at most ${FLAG_MAX_USER_IDS} items`);
  const userIds = (input.userIds as unknown[]).map((id) => {
    if (typeof id !== 'string' || !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id)) fail('userIds must be UUIDs');
    return id.toLowerCase();
  });
  return { enabled: input.enabled, userIds: [...new Set(userIds)].sort(), percentage: input.percentage };
}

/** Stable 0-99 bucket per flag and user, so one user does not flip between on and off. */
export function rolloutBucket(key: string, userId: string): number {
  return createHash('sha256').update(`${key}:${userId.toLowerCase()}`).digest().readUInt32BE(0) % 100;
}

export function isFlagOn(key: string, state: FlagState, userId: string): boolean {
  if (!state.enabled) return false;
  if (state.userIds.includes(userId.toLowerCase())) return true;
  return rolloutBucket(key, userId) < state.percentage;
}
