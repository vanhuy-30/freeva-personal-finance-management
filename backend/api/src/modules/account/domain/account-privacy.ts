export class AccountPrivacyError extends Error {
  constructor(readonly code: 'SESSION_INVALID' | 'ACCOUNT_UNAVAILABLE') {
    super(code);
    this.name = 'AccountPrivacyError';
  }
}
