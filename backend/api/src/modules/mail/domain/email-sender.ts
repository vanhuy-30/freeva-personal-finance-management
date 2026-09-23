/** Provider-neutral port. Delivery acceptance is not an inbox-delivery guarantee. */
export interface EmailMessage {
  /** Stable outbox ID; reused on retry, changed when a challenge is replaced. */
  deliveryId: string;
  to: string;
  subject: string;
  text: string;
}

export const EMAIL_SENDER = Symbol('EMAIL_SENDER');

export interface EmailSender {
  /** Resolve only after the provider accepts the recipient. Throw without PII. */
  send(message: EmailMessage): Promise<void>;
}
