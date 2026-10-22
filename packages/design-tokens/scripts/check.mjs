// Validates tokens.json: references resolve, text pairs meet WCAG AA, highlight/muted never used as text.
// Run: node packages/design-tokens/scripts/check.mjs
import { contrast, resolveValue, semanticColor, semanticLeaves, tokens } from './lib.mjs';

const TEXT = 4.5;
const UI = 3;

// [foreground, background, minimum ratio]
const pairs = [
  ...['bg.canvas', 'bg.surface', 'bg.subtle'].flatMap((bg) => [
    ['text.primary', bg, TEXT],
    ['text.secondary', bg, TEXT],
    ['text.link', bg, TEXT],
  ]),
  ['text.onWash', 'bg.wash', TEXT],
  ['text.primary', 'bg.wash', TEXT],
  ['text.onAction', 'action.primary', TEXT],
  ['text.onAction', 'action.primaryPressed', TEXT],
  ['text.onAction', 'action.danger', TEXT],
  ['text.onInk', 'action.ink', TEXT],
  ['money.income', 'bg.surface', TEXT],
  ['money.expense', 'bg.surface', TEXT],
  ['money.transfer', 'bg.surface', TEXT],
  ...['success', 'danger', 'warning', 'info'].flatMap((s) => [
    [`status.${s}`, `status.${s}Bg`, TEXT],
    [`status.${s}`, 'bg.surface', TEXT],
  ]),
  ...['blue', 'violet', 'cyan', 'green'].map((t) => [`tint.${t}Fg`, `tint.${t}`, UI]),
  ['border.focus', 'bg.surface', UI],
  ['border.selected', 'bg.surface', UI],
  ['data.1', 'bg.surface', UI],
];

const failures = [];

for (const mode of ['light', 'dark']) {
  for (const [fg, bg, min] of pairs) {
    const ratio = contrast(semanticColor(fg, mode), semanticColor(bg, mode));
    if (ratio < min) failures.push(`${mode}: ${fg} on ${bg} = ${ratio.toFixed(2)} (< ${min})`);
  }
}

const banned = [tokens.color.brand.highlight, tokens.color.brand.muted].map((h) => h.toUpperCase());
for (const [path, value] of semanticLeaves()) {
  for (const mode of ['light', 'dark']) {
    const hex = String(resolveValue(value, mode)).toUpperCase();
    if (path[0] === 'text' && banned.includes(hex)) failures.push(`${mode}: text.${path.slice(1).join('.')} uses ${hex}, which is not a text colour`);
  }
}

// Every component reference must resolve.
(function walk(node, path) {
  for (const [key, value] of Object.entries(node)) {
    const here = [...path, key].join('.');
    if (typeof value === 'string') {
      try { resolveValue(value, 'light'); } catch (e) { failures.push(`${here}: ${e.message}`); }
    } else if (value && typeof value === 'object' && !Array.isArray(value)) walk(value, [...path, key]);
  }
})(tokens.component, ['component']);

if (failures.length) {
  console.error(`Token check failed:\n  ${failures.join('\n  ')}`);
  process.exit(1);
}
console.log(`Token check passed: ${pairs.length * 2} contrast pairs, references and text rules.`);
