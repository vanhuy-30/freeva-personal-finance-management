// WA-P5-001: turn what staff type into the typed value BE-P5-E08 expects, and back.
// Pure (no React, no fetch) so it runs under `node --test`. The API stays the source of truth
// for limits; this only parses text and gives early, readable errors.

export type ConfigType =
  | "integer"
  | "integer_list"
  | "money_minor_list"
  | "enum"
  | "enum_list"
  | "pair_list"
  | "time";

export type ConfigDefinition = {
  type: ConfigType;
  default: ConfigValue;
  description: string;
  min?: number;
  max?: number;
  minItems?: number;
  maxItems?: number;
  values?: string[];
  currencyCode?: string;
  /** `pair_list` only: longest text before the colon (BE-P5-E03). */
  maxTextLength?: number;
  /** false on fixed technical limits (`limit.*`): shown, never edited (BE-P5-001). */
  editable?: false;
};

export type ConfigValue = number | string | number[] | string[];

export type ParseResult =
  | { ok: true; value: ConfigValue }
  | { ok: false; message: string };

function items(text: string): string[] {
  return text
    .split(/[,;\n]/)
    .map((part) => part.trim())
    .filter((part) => part.length > 0);
}

function wholeNumber(text: string): number | null {
  return /^-?\d+$/.test(text) ? Number(text) : null;
}

/** Text from the form → typed value. Range checks repeat the API's so staff see them before saving. */
export function parseConfigInput(definition: ConfigDefinition, text: string): ParseResult {
  const raw = text.trim();
  switch (definition.type) {
    case "integer": {
      const value = wholeNumber(raw);
      if (value === null) return { ok: false, message: "Nhập một số nguyên." };
      return inRange(definition, value) ?? { ok: true, value };
    }
    case "integer_list": {
      const parts = items(raw);
      const values: number[] = [];
      for (const part of parts) {
        const value = wholeNumber(part);
        if (value === null) return { ok: false, message: `"${part}" không phải số nguyên.` };
        const error = inRange(definition, value);
        if (error) return error;
        values.push(value);
      }
      return countError(definition, values.length) ?? ascendingError(values) ?? { ok: true, value: values };
    }
    case "money_minor_list": {
      const values: string[] = [];
      for (const part of items(raw)) {
        const digits = part.replace(/[.\s_]/g, "");
        if (!/^[1-9]\d{0,17}$/.test(digits)) return { ok: false, message: `"${part}" không phải số tiền dương.` };
        values.push(digits);
      }
      return (
        countError(definition, values.length) ??
        ascendingError(values.map((value) => BigInt(value))) ?? { ok: true, value: values }
      );
    }
    case "enum": {
      if (!definition.values?.includes(raw)) return { ok: false, message: `Chọn một trong: ${definition.values?.join(", ")}.` };
      return { ok: true, value: raw };
    }
    case "enum_list": {
      const values = items(raw);
      const unknown = values.find((value) => !definition.values?.includes(value));
      if (unknown) return { ok: false, message: `"${unknown}" không có trong: ${definition.values?.join(", ")}.` };
      if (new Set(values).size !== values.length) return { ok: false, message: "Mỗi giá trị chỉ ghi một lần." };
      return countError(definition, values.length) ?? { ok: true, value: values };
    }
    case "pair_list": {
      // One pair per line: names may contain commas ("Co.opmart, Q1"), never line breaks.
      const values: string[] = [];
      const seen = new Set<string>();
      for (const line of raw.split("\n").map((part) => part.trim()).filter((part) => part.length > 0)) {
        const at = line.lastIndexOf(":");
        const name = at > 0 ? line.slice(0, at).trim() : "";
        const target = at > 0 ? line.slice(at + 1).trim() : "";
        if (!name || !target) return { ok: false, message: `"${line}" phải có dạng "Tên: icon".` };
        if (definition.maxTextLength !== undefined && name.length > definition.maxTextLength) {
          return { ok: false, message: `"${name}" dài quá ${definition.maxTextLength} ký tự.` };
        }
        if (!definition.values?.includes(target)) return { ok: false, message: `"${target}" không phải icon danh mục.` };
        const key = name.normalize("NFD").replace(/[\u0300-\u036f]/g, "").replace(/đ/gi, "d").toLowerCase().replace(/\s+/g, " ");
        if (seen.has(key)) return { ok: false, message: `"${name}" ghi hai lần.` };
        seen.add(key);
        values.push(`${name}: ${target}`);
      }
      return countError(definition, values.length) ?? { ok: true, value: values };
    }
    case "time": {
      if (!/^([01]\d|2[0-3]):[0-5]\d$/.test(raw)) return { ok: false, message: "Nhập giờ dạng HH:mm, ví dụ 21:00." };
      return { ok: true, value: raw };
    }
  }
}

function inRange(definition: ConfigDefinition, value: number): ParseResult | null {
  if (definition.min !== undefined && value < definition.min) return { ok: false, message: `Nhỏ nhất là ${definition.min}.` };
  if (definition.max !== undefined && value > definition.max) return { ok: false, message: `Lớn nhất là ${definition.max}.` };
  return null;
}

function countError(definition: ConfigDefinition, count: number): ParseResult | null {
  const min = definition.minItems ?? 0;
  const max = definition.maxItems ?? Number.POSITIVE_INFINITY;
  if (count < min || count > max) {
    return { ok: false, message: max === Number.POSITIVE_INFINITY ? `Cần ít nhất ${min} giá trị.` : `Cần từ ${min} đến ${max} giá trị.` };
  }
  return null;
}

function ascendingError(values: (number | bigint)[]): ParseResult | null {
  for (let i = 1; i < values.length; i += 1) {
    if (!(values[i - 1] < values[i])) return { ok: false, message: "Các giá trị phải tăng dần và không trùng." };
  }
  return null;
}

/** Typed value → the text shown in the input. */
export function toInputText(definition: ConfigDefinition, value: ConfigValue): string {
  if (Array.isArray(value) && definition.type === "pair_list") return (value as string[]).join("\n");
  if (Array.isArray(value)) {
    return definition.type === "money_minor_list"
      ? (value as string[]).map(groupDigits).join(", ")
      : value.join(", ");
  }
  return String(value);
}

/** Readable value for old/new comparison and the "Mặc định" line. */
export function describeValue(definition: ConfigDefinition, value: ConfigValue): string {
  const text = toInputText(definition, value);
  if (text === "") return "(trống)";
  if (definition.type === "money_minor_list" && definition.currencyCode) return `${text} ${definition.currencyCode}`;
  return text;
}

/** Limits line under the input, e.g. "1–100 · 1–4 giá trị · tăng dần". */
export function describeLimits(definition: ConfigDefinition): string {
  const parts: string[] = [];
  if (definition.min !== undefined && definition.max !== undefined) parts.push(`${definition.min}–${definition.max}`);
  if (definition.minItems !== undefined && definition.maxItems !== undefined) parts.push(`${definition.minItems}–${definition.maxItems} giá trị`);
  if (definition.type === "integer_list" || definition.type === "money_minor_list") parts.push("tăng dần, cách nhau dấu phẩy");
  if (definition.type === "enum_list") parts.push("theo thứ tự hiện, cách nhau dấu phẩy");
  if (definition.type === "enum" || definition.type === "enum_list") parts.push(`giá trị: ${definition.values?.join(", ")}`);
  if (definition.type === "pair_list") parts.push(`mỗi dòng "Tên: icon", tên tối đa ${definition.maxTextLength ?? "?"} ký tự`);
  if (definition.type === "time") parts.push("HH:mm");
  return parts.join(" · ");
}

function groupDigits(value: string): string {
  return value.replace(/\B(?=(\d{3})+(?!\d))/g, ".");
}

export type FlagInput = { enabled: boolean; percentage: number; userIds: string[] };

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export function parseFlagInput(enabled: boolean, percentageText: string, userIdsText: string):
  | { ok: true; value: FlagInput }
  | { ok: false; field: "percentage" | "userIds"; message: string } {
  const percentage = wholeNumber(percentageText.trim());
  if (percentage === null || percentage < 0 || percentage > 100) {
    return { ok: false, field: "percentage", message: "Nhập số nguyên từ 0 đến 100." };
  }
  const userIds = items(userIdsText).map((id) => id.toLowerCase());
  const bad = userIds.find((id) => !UUID.test(id));
  if (bad) return { ok: false, field: "userIds", message: `"${bad}" không phải UUID.` };
  if (userIds.length > 500) return { ok: false, field: "userIds", message: "Tối đa 500 user." };
  return { ok: true, value: { enabled, percentage, userIds: [...new Set(userIds)] } };
}

export function sameValue(a: unknown, b: unknown): boolean {
  return JSON.stringify(a) === JSON.stringify(b);
}

/** "budget.alertThresholdOptions" → "budget"; flags have no group. */
export function configGroup(key: string): string {
  return key.includes(".") ? key.slice(0, key.indexOf(".")) : "";
}
