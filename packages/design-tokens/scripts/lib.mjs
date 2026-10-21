// Shared helpers for the token build and checks. No dependencies.
import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

export const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
export const tokens = JSON.parse(readFileSync(resolve(root, 'tokens.json'), 'utf8'));

const REF = /^\{([^}]+)\}$/;

export function lookup(path) {
  const value = path.split('.').reduce((node, key) => node?.[key], tokens);
  if (value === undefined) throw new Error(`Unknown token reference {${path}}`);
  return value;
}

// Follows {a.b.c} references until a literal; `mode` picks light/dark on semantic leaves.
export function resolveValue(value, mode, seen = []) {
  if (typeof value === 'string') {
    const match = value.match(REF);
    if (!match) return value;
    if (seen.includes(match[1])) throw new Error(`Circular reference: ${[...seen, match[1]].join(' → ')}`);
    return resolveValue(lookup(match[1]), mode, [...seen, match[1]]);
  }
  if (value && typeof value === 'object' && !Array.isArray(value) && 'light' in value && 'dark' in value) {
    return resolveValue(value[mode], mode, seen);
  }
  return value;
}

// Semantic leaves as [['bg','canvas'], {light, dark}].
export function semanticLeaves(node = tokens.semantic.color, path = []) {
  return Object.entries(node).flatMap(([key, value]) =>
    value && typeof value === 'object' && 'light' in value
      ? [[[...path, key], value]]
      : semanticLeaves(value, [...path, key]));
}

export function semanticColor(path, mode) {
  return resolveValue(`{semantic.color.${path}}`, mode);
}

function channel(hex2) {
  const c = parseInt(hex2, 16) / 255;
  return c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4;
}

export function luminance(hex) {
  const h = hex.replace('#', '');
  if (h.length !== 6) throw new Error(`Contrast needs an opaque #RRGGBB colour, got ${hex}`);
  return 0.2126 * channel(h.slice(0, 2)) + 0.7152 * channel(h.slice(2, 4)) + 0.0722 * channel(h.slice(4, 6));
}

export function contrast(a, b) {
  const [hi, lo] = [luminance(a), luminance(b)].sort((x, y) => y - x);
  return (hi + 0.05) / (lo + 0.05);
}

export const kebab = (s) => s.replace(/([a-z0-9])([A-Z])/g, '$1-$2').toLowerCase();
