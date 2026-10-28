import { createHash } from 'node:crypto';

/** Deterministic UUID v4-shaped id from rule + calendar day + leg index for create idempotency. */
export function occurrenceClientId(ruleId: string, occurredOn: string, legIndex: number): string {
  const hash = createHash('sha256').update(`${ruleId}|${occurredOn}|${legIndex}`).digest();
  const bytes = Buffer.from(hash.subarray(0, 16));
  bytes[6] = (bytes[6]! & 0x0f) | 0x40;
  bytes[8] = (bytes[8]! & 0x3f) | 0x80;
  const hex = bytes.toString('hex');
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}
