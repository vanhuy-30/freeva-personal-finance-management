export const FEEDBACK_KINDS = ['bug', 'idea', 'praise'] as const;
export const FEEDBACK_TOPICS = ['record', 'reports', 'wallets', 'categories', 'appearance', 'other'] as const;
export const FEEDBACK_PER_HOUR = 5;

export class FeedbackError extends Error {
  constructor(readonly code: 'RATE_LIMITED') { super(code); }
}
export interface FeedbackInput {
  kind: (typeof FEEDBACK_KINDS)[number];
  topic: (typeof FEEDBACK_TOPICS)[number];
  message: string;
  allowReply: boolean;
  appVersion: string;
}
export const FEEDBACK_REPOSITORY = Symbol('FEEDBACK_REPOSITORY');
export interface FeedbackRepository {
  /** Stores it unless the user already sent [limit] in the last hour; false then. */
  add(userId: string, input: FeedbackInput, limit: number): Promise<boolean>;
}
