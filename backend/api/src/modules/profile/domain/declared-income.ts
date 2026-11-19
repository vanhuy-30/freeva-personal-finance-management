/**
 * BE-P6-002: monthly income the user declares at onboarding, as a band in minor units of the
 * profile's default currency. Kept apart from actual income, which is averaged from transactions.
 * `maxMinor` null is the open top band (e.g. "Trên 40 triệu"). A legacy exact amount is [x, x].
 */
export type DeclaredIncomeBand = { minMinor: bigint; maxMinor: bigint | null };

/** Same rules as the DB check: min >= 0, max >= min, and an open band needs min > 0. */
export function isValidIncomeBand(band: DeclaredIncomeBand): boolean {
  if (band.minMinor < 0n) return false;
  if (band.maxMinor === null) return band.minMinor > 0n;
  return band.maxMinor >= band.minMinor;
}

/** Point used for suggestions: middle of the band, or min * 5/4 for the open top band. Integer division. */
export function incomeBandMidpoint(band: DeclaredIncomeBand): bigint {
  if (band.maxMinor === null) return (band.minMinor * 5n) / 4n;
  return (band.minMinor + band.maxMinor) / 2n;
}

/** Band from the two nullable columns; null when not declared. */
export function bandFromColumns(minMinor: bigint | null, maxMinor: bigint | null): DeclaredIncomeBand | null {
  return minMinor === null ? null : { minMinor, maxMinor };
}
