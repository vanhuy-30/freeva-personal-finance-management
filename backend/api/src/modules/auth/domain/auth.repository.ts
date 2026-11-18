export type TokenPurpose = 'verify_email' | 'reset_password';
export interface AuthUser {
  id: string;
  email: string;
  passwordHash: string | null;
  emailVerifiedAt: Date | null;
}
export interface EmailChallenge {
  tokenHash: string;
  encryptedToken: string;
  expiresAt: Date;
}
export interface Session {
  id: string;
  userId: string;
  createdAt: Date;
  expiresAt: Date;
  lastUsedAt: Date;
}
/** The phone a session belongs to (BE-P6-001). One session per [id]. */
export interface SessionDevice {
  id: string;
  name: string | null;
  platform: 'ios' | 'android';
  osVersion: string | null;
}
/** A session as listed on Phiên đăng nhập. Device fields are null on old sessions. */
export interface SessionInfo extends Session {
  deviceName: string | null;
  platform: string | null;
  osVersion: string | null;
}
/** When the person agreed, and to which version of the Terms and Privacy policy. */
export interface TermsConsent {
  acceptedAt: Date;
  version: string;
}
export interface MailJob {
  id: string;
  email: string;
  purpose: TokenPurpose;
  encryptedToken: string;
}
export const AUTH_REPOSITORY = Symbol('AUTH_REPOSITORY');
export interface AuthRepository {
  register(
    email: string,
    passwordHash: string,
    challenge: EmailChallenge,
    terms: TermsConsent,
  ): Promise<void>;
  findUser(email: string): Promise<AuthUser | null>;
  issueChallenge(
    email: string,
    purpose: TokenPurpose,
    challenge: EmailChallenge,
  ): Promise<void>;
  consumeChallenge(
    tokenHash: string,
    purpose: TokenPurpose,
    passwordHash?: string,
  ): Promise<boolean>;
  createSession(
    userId: string,
    passwordHash: string,
    tokenHash: string,
    expiresAt: Date,
    device?: SessionDevice,
  ): Promise<Session | null>;
  findSession(tokenHash: string): Promise<Session | null>;
  /** Marks the session as used now (callers throttle it). */
  touchSession(sessionId: string, at: Date): Promise<void>;
  listSessions(userId: string): Promise<SessionInfo[]>;
  findUserById(userId: string): Promise<AuthUser | null>;
  /**
   * Swaps the hash only while it still equals [currentHash], ends every other
   * session and unused email tokens, and records the change. False when the
   * password changed in the meantime.
   */
  changePassword(
    userId: string,
    currentHash: string,
    newHash: string,
    keepSessionId: string,
  ): Promise<boolean>;
  revoke(userId: string, sessionId?: string): Promise<void>;
  takeRateLimit(
    key: string,
    limit: number,
    windowSeconds: number,
  ): Promise<number>;
  claimMail(): Promise<MailJob | null>;
  completeMail(id: string): Promise<void>;
  cleanup(): Promise<void>;
}
