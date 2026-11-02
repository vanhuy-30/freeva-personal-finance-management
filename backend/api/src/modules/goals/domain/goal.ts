import { CATEGORY_ICONS, CATEGORY_PALETTE } from '../../categories/domain/category';

export const GOAL_KINDS = ['emergency', 'home', 'car', 'travel', 'education', 'wedding', 'retirement', 'custom'] as const;
export type GoalKind = (typeof GOAL_KINDS)[number];

export const GOAL_ENTRY_KINDS = ['contribute', 'withdraw'] as const;
export type GoalEntryKind = (typeof GOAL_ENTRY_KINDS)[number];

export class GoalError extends Error {
  constructor(
    readonly code: 'VALIDATION_ERROR' | 'GOAL_NOT_FOUND' | 'GOAL_CONFLICT' | 'INSUFFICIENT_GOAL_BALANCE',
  ) {
    super(code);
    this.name = 'GoalError';
  }
}

export type GoalPreset = { kind: GoalKind; icon: string; colorToken: string };

/** Ready-made groups (BE-P3-E01). The user still names the goal; icon and colour are catalog tokens, never hex. */
export const GOAL_PRESETS: readonly GoalPreset[] = [
  { kind: 'emergency', icon: 'insurance', colorToken: 'color.semantic.warning' },
  { kind: 'home', icon: 'housing', colorToken: 'color.brand.primary' },
  { kind: 'car', icon: 'transport', colorToken: 'color.category.blueDeep' },
  { kind: 'travel', icon: 'travel', colorToken: 'color.category.oceanDeep' },
  { kind: 'education', icon: 'education', colorToken: 'color.category.violetDeep' },
  { kind: 'wedding', icon: 'gifts', colorToken: 'color.category.pink' },
  { kind: 'retirement', icon: 'other_income', colorToken: 'color.semantic.success' },
  { kind: 'custom', icon: 'category', colorToken: 'color.brand.secondary' },
];

export function presetOf(kind: GoalKind): GoalPreset {
  return GOAL_PRESETS.find(preset => preset.kind === kind)!;
}

export type GoalRecord = {
  id: string;
  clientId: string;
  kind: GoalKind;
  name: string;
  currencyCode: string;
  targetMinor: bigint;
  currentMinor: bigint;
  /** Calendar day YYYY-MM-DD or null. */
  targetDate: string | null;
  accountId: string;
  monthlyContributionMinor: bigint | null;
  icon: string;
  colorToken: string | null;
  archivedAt: Date | null;
  version: number;
  createdAt: Date;
  updatedAt: Date;
};

export function validateName(name: string): void {
  const trimmed = name.trim();
  if (trimmed.length < 1 || trimmed.length > 80) throw new GoalError('VALIDATION_ERROR');
}

export function validateTarget(targetMinor: bigint): void {
  if (targetMinor <= 0n) throw new GoalError('VALIDATION_ERROR');
}

export function validateCurrent(currentMinor: bigint): void {
  if (currentMinor < 0n) throw new GoalError('VALIDATION_ERROR');
}

export function validateMonthly(monthlyMinor: bigint | null): void {
  if (monthlyMinor !== null && monthlyMinor < 0n) throw new GoalError('VALIDATION_ERROR');
}

export function validateLook(icon: string, colorToken: string | null): void {
  if (!(CATEGORY_ICONS as readonly string[]).includes(icon)) throw new GoalError('VALIDATION_ERROR');
  if (colorToken !== null && !(CATEGORY_PALETTE as readonly string[]).includes(colorToken)) {
    throw new GoalError('VALIDATION_ERROR');
  }
}

export function remainingMinor(targetMinor: bigint, currentMinor: bigint): bigint {
  return currentMinor >= targetMinor ? 0n : targetMinor - currentMinor;
}

/** `current * 10000 / target`, floored; 10000 = 100,00%. Can exceed 10000 when over-saved. */
export function percentBps(targetMinor: bigint, currentMinor: bigint): number {
  if (targetMinor <= 0n) return 0;
  return Number((currentMinor * 10000n) / targetMinor);
}

const parts = (day: string): [number, number, number] => {
  const [y, m, d] = day.split('-').map(Number);
  return [y, m, d];
};

/**
 * Whole calendar months from `today` to `targetDate`, counting a started month as a full one:
 * 2026-11-02 → 2026-12-02 is 1, → 2026-12-03 is 2. A target in the past (or today) gives 0.
 */
export function monthsLeft(today: string, targetDate: string): number {
  const [ty, tm, td] = parts(today);
  const [gy, gm, gd] = parts(targetDate);
  let months = (gy - ty) * 12 + (gm - tm);
  if (gd > td) months += 1;
  return months > 0 ? months : 0;
}

/** `ceil((target - current) / months)`; 0 when reached; null when there is no future date to divide by. */
export function requiredPerMonth(targetMinor: bigint, currentMinor: bigint, months: number | null): bigint | null {
  const left = remainingMinor(targetMinor, currentMinor);
  if (left === 0n) return 0n;
  if (months === null || months <= 0) return null;
  const divisor = BigInt(months);
  return (left + divisor - 1n) / divisor;
}

export type GoalStatus = 'reached' | 'overdue' | 'active';

export function goalStatus(
  targetMinor: bigint,
  currentMinor: bigint,
  targetDate: string | null,
  today: string,
): GoalStatus {
  if (currentMinor >= targetMinor) return 'reached';
  if (targetDate !== null && targetDate <= today) return 'overdue';
  return 'active';
}

/** Share of average monthly income the required saving takes, in basis points; null when income is unknown. */
export function incomeShareBps(requiredMinor: bigint | null, monthlyIncomeMinor: bigint | null): number | null {
  if (requiredMinor === null || monthlyIncomeMinor === null || monthlyIncomeMinor <= 0n) return null;
  return Number((requiredMinor * 10000n) / monthlyIncomeMinor);
}
