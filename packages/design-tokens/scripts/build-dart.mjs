// Generates apps/mobile/lib/core/theme/tokens.g.dart from tokens.json.
// Run: node packages/design-tokens/scripts/build-dart.mjs [--check]
import { readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { resolveValue, root, semanticLeaves, tokens } from './lib.mjs';

const camel = (parts) => parts
  .map((p, i) => (i === 0 ? p : p.charAt(0).toUpperCase() + p.slice(1)))
  .join('');

// '#RRGGBB' or '#RRGGBBAA' → Color(0xAARRGGBB).
function dartColor(hex, opacity = 1) {
  const h = hex.replace('#', '').toUpperCase();
  const rgb = h.slice(0, 6);
  const baseAlpha = h.length === 8 ? parseInt(h.slice(6, 8), 16) / 255 : 1;
  const alpha = Math.round(baseAlpha * opacity * 255).toString(16).padStart(2, '0').toUpperCase();
  return `Color(0x${alpha}${rgb})`;
}

const num = (v) => (Number.isInteger(v) ? `${v}.0` : `${v}`);

// Semantic leaves plus component colour leaves that point at colours.
const colorFields = semanticLeaves().map(([path, value]) => ({
  name: camel(path),
  light: dartColor(resolveValue(value, 'light')),
  dark: dartColor(resolveValue(value, 'dark')),
}));

function componentColors(node, path) {
  return Object.entries(node).flatMap(([key, value]) => {
    if (value && typeof value === 'object' && !Array.isArray(value)) return componentColors(value, [...path, key]);
    if (typeof value !== 'string' || !value.includes('color.')) return [];
    return [{
      name: camel([...path, key]),
      light: dartColor(resolveValue(value, 'light')),
      dark: dartColor(resolveValue(value, 'dark')),
    }];
  });
}
colorFields.push(...componentColors(tokens.component, []));

// Balance-card wash layers carry their own opacity per mode.
tokens.component.balanceCard.wash.forEach((layer) => {
  const hex = resolveValue(layer.color, 'light');
  colorFields.push({
    name: camel(['balanceCard', 'wash', layer.center]),
    light: dartColor(hex, layer.opacityLight),
    dark: dartColor(hex, layer.opacityDark),
  });
});

const fieldsDecl = colorFields.map((f) => `  final Color ${f.name};`).join('\n');
const ctorParams = colorFields.map((f) => `    required this.${f.name},`).join('\n');
const instance = (mode) => colorFields.map((f) => `    ${f.name}: ${f[mode]},`).join('\n');
const copyParams = colorFields.map((f) => `    Color? ${f.name},`).join('\n');
const copyBody = colorFields.map((f) => `      ${f.name}: ${f.name} ?? this.${f.name},`).join('\n');
const lerpBody = colorFields.map((f) => `      ${f.name}: Color.lerp(${f.name}, other.${f.name}, t)!,`).join('\n');

const primitives = Object.entries(tokens.primitive.color).flatMap(([family, value]) =>
  typeof value === 'string'
    ? [`  static const Color ${family} = ${dartColor(value)};`]
    : Object.entries(value).map(([step, hex]) => `  static const Color ${family}${step} = ${dartColor(hex)};`));

const consts = (name, entries) => [
  `abstract final class ${name} {`,
  ...entries.map(([k, v]) => `  static const double ${k} = ${num(v)};`),
  '}',
].join('\n');

const DART_RESERVED = new Set(['default']);
const keyName = (k) => (/^\d/.test(k) ? `s${k}` : DART_RESERVED.has(k) ? `${k}Value` : k);

const component = tokens.component;
const componentNums = [
  ['buttonHeight', resolveValue(component.button.height)],
  ['buttonRadius', resolveValue(component.button.radius)],
  ['inputRadius', resolveValue(component.input.radius)],
  ['navHeight', resolveValue(component.nav.height)],
  ['navFabSize', resolveValue(component.nav.fabSize)],
  ['navFabLift', component.nav.fabLift],
  ['navFabNotch', component.nav.fabNotch],
  ['cardRadius', resolveValue(component.card.radius)],
  ['listRadius', resolveValue(component.list.radius)],
  ['listRowHeight', resolveValue(component.list.rowHeight)],
  ['sheetRadius', resolveValue(component.sheet.radius)],
  ['balanceCardRadius', resolveValue(component.balanceCard.radius)],
];

const shadow = (s) => `BoxShadow(offset: Offset(${num(s.x)}, ${num(s.y)}), blurRadius: ${num(s.blur)}, color: ${dartColor(s.color)})`;
const elevations = Object.entries(tokens.elevation).map(([k, list]) =>
  `  static const List<BoxShadow> ${keyName(k)} = [${list.map(shadow).join(', ')}];`);

const typo = tokens.typography;
const textStyle = (s, size, lineHeight) => [
  'TextStyle(',
  `    fontFamily: '${typo.fontFamily}',`,
  `    fontSize: ${num(size)},`,
  `    height: ${+(lineHeight / size).toFixed(4)},`,
  `    fontWeight: FontWeight.w${s.weight},`,
  `    letterSpacing: ${num(s.letterSpacing)},`,
  ...(s.tabular ? ["    fontFeatures: [FontFeature.tabularFigures()],"] : []),
  '  )',
].join('\n');
const styles = Object.entries(typo.style).flatMap(([name, s]) => [
  `  static const TextStyle ${name} = ${textStyle(s, s.size, s.lineHeight)};`,
  ...(s.compactSize ? [`  static const TextStyle ${name}Compact = ${textStyle(s, s.compactSize, s.compactLineHeight)};`] : []),
]);

const legacyPalette = ['brand', 'neutral', 'semantic', 'gradient', 'dark'].flatMap((group) =>
  Object.entries(tokens.color[group]).map(([key, hex]) => `  'color.${group}.${key}': ${dartColor(hex)},`));

const dart = `// GENERATED by packages/design-tokens/scripts/build-dart.mjs from tokens.json.
// Do not edit or run dart format on it by hand. Spec: docs/brand/design-system.md.
// ignore_for_file: public_member_api_docs, lines_longer_than_80_chars

import 'package:flutter/material.dart';

/// Semantic and component colours. Read with \`context.colors\`.
@immutable
class FreevaColors extends ThemeExtension<FreevaColors> {
  const FreevaColors({
${ctorParams}
  });

${fieldsDecl}

  static const FreevaColors light = FreevaColors(
${instance('light')}
  );

  static const FreevaColors dark = FreevaColors(
${instance('dark')}
  );

  @override
  FreevaColors copyWith({
${copyParams}
  }) {
    return FreevaColors(
${copyBody}
    );
  }

  @override
  FreevaColors lerp(ThemeExtension<FreevaColors>? other, double t) {
    if (other is! FreevaColors) return this;
    return FreevaColors(
${lerpBody}
    );
  }
}

/// Raw scales. Widgets use semantic colours; primitives only where a spec names a step.
abstract final class FreevaPrimitive {
${primitives.join('\n')}
}

${consts('FreevaSpace', Object.entries(tokens.space).map(([k, v]) => [keyName(k), v]))}

${consts('FreevaRadius', Object.entries(tokens.radius))}

${consts('FreevaSize', Object.entries(tokens.size))}

${consts('FreevaLayout', Object.entries(tokens.layout))}

${consts('FreevaBorder', Object.entries(tokens.border).map(([k, v]) => [keyName(k), v]))}

${consts('FreevaComponent', componentNums)}

abstract final class FreevaElevation {
${elevations.join('\n')}
}

abstract final class FreevaMotion {
${Object.entries(tokens.motion.duration).map(([k, v]) => `  static const Duration ${k} = Duration(milliseconds: ${v});`).join('\n')}
  static const Curve standard = Cubic(${tokens.motion.easing.standard.map(num).join(', ')});
  static const double pressedScale = ${num(tokens.motion.pressedScale)};
}

abstract final class FreevaTypography {
  static const String fontFamily = '${typo.fontFamily}';
  static const double maxTextScale = ${num(typo.maxTextScale)};
  static const double moneyDisplayMaxScale = ${num(typo.style.moneyDisplay.maxScale)};
${styles.join('\n')}
}

/// Category colour tokens returned by GET /categories/options (legacy \`color.*\` keys).
const Map<String, Color> categoryPalette = {
${legacyPalette.join('\n')}
};
`;

const out = resolve(root, '../../apps/mobile/lib/core/theme/tokens.g.dart');
if (process.argv.includes('--check')) {
  let current = '';
  try { current = readFileSync(out, 'utf8'); } catch { /* missing counts as stale */ }
  if (current !== dart) {
    console.error('tokens.g.dart is stale. Run: node packages/design-tokens/scripts/build-dart.mjs');
    process.exit(1);
  }
  console.log('tokens.g.dart is up to date.');
} else {
  writeFileSync(out, dart);
  console.log(`Wrote ${out}`);
}
