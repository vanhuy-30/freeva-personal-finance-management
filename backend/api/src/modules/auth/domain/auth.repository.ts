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
  ): Promise<Session | null>;
  findSession(tokenHash: string): Promise<Session | null>;
  listSessions(userId: string): Promise<Session[]>;
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
