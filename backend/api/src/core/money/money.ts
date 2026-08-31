/**
 * Integer minor units only. Never use number/float for money arithmetic.
 * JSON transport: string (see ADR 006).
 */
export function parseMinor(value: string): bigint {
  if (!/^-?\d+$/.test(value)) {
    throw new Error('INVALID_MINOR_UNITS');
  }
  return BigInt(value);
}

export function formatMinor(value: bigint): string {
  return value.toString();
}

export function addMinor(left: bigint, right: bigint): bigint {
  return left + right;
}

export function assertTransferBalanced(
  sourceMinor: bigint,
  destMinor: bigint,
): void {
  if (sourceMinor + destMinor !== 0n) {
    throw new Error('UNBALANCED_TRANSFER');
  }
}
