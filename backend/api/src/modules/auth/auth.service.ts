import {
  BadRequestException,
  ForbiddenException,
  HttpException,
  Inject,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import {
  AUTH_REPOSITORY,
  type AuthRepository,
  type TokenPurpose,
} from './domain/auth.repository';
import { AuthCrypto } from './infrastructure/auth-crypto';

/** Version of the Terms and Privacy policy people agree to at sign-up. */
export const TERMS_VERSION = '2026-10';

export const accepted = {
  message: 'If the account is eligible, an email will be sent.',
};
export const unauthorized = () =>
  new UnauthorizedException({
    error: {
      code: 'INVALID_CREDENTIALS',
      message: 'Invalid credentials',
    },
  });

@Injectable()
export class AuthService {
  constructor(
    @Inject(AUTH_REPOSITORY) private readonly repository: AuthRepository,
    private readonly crypto: AuthCrypto,
  ) {}

  private challenge(purpose: TokenPurpose) {
    const token = this.crypto.token();
    return {
      tokenHash: this.crypto.digest(token),
      encryptedToken: this.crypto.encrypt(token),
      expiresAt: new Date(
        Date.now() + (purpose === 'verify_email' ? 24 * 60 : 30) * 60_000,
      ),
    };
  }

  async emailStep(email: string): Promise<{ nextStep: 'login' | 'register' }> {
    // MOB-P1-001: explicit email-first UX; return no user details or credentials.
    // Legacy accounts also go to login, never credential replacement via register.
    const user = await this.repository.findUser(email);
    return { nextStep: user ? 'login' : 'register' };
  }

  async register(email: string, password: string) {
    const passwordHash = await this.crypto.hashPassword(password);
    await this.repository.register(
      email,
      passwordHash,
      this.challenge('verify_email'),
      { acceptedAt: new Date(), version: TERMS_VERSION },
    );
    return accepted;
  }

  async requestEmail(email: string, purpose: TokenPurpose) {
    await this.repository.issueChallenge(
      email,
      purpose,
      this.challenge(purpose),
    );
    return accepted;
  }

  async consume(
    token: string,
    purpose: TokenPurpose,
    password?: string,
  ): Promise<void> {
    const passwordHash =
      password === undefined
        ? undefined
        : await this.crypto.hashPassword(password);
    if (
      !(await this.repository.consumeChallenge(
        this.crypto.digest(token),
        purpose,
        passwordHash,
      ))
    ) {
      throw new BadRequestException({
        error: {
          code: 'INVALID_TOKEN',
          message: 'Token is invalid or expired',
        },
      });
    }
  }

  async login(email: string, password: string) {
    const user = await this.repository.findUser(email);
    const valid = await this.crypto.verifyPassword(
      user?.passwordHash ?? null,
      password,
    );
    if (!valid || !user?.passwordHash) throw unauthorized();
    const accessToken = this.crypto.token();
    const session = await this.repository.createSession(
      user.id,
      user.passwordHash,
      this.crypto.digest(accessToken),
      new Date(Date.now() + 7 * 24 * 60 * 60_000),
    );
    if (!session) throw unauthorized();
    return {
      accessToken,
      tokenType: 'Bearer' as const,
      expiresAt: session.expiresAt,
      sessionId: session.id,
    };
  }

  async authenticate(token: string) {
    if (!/^[a-f0-9]{64}$/.test(token)) throw unauthorized();
    const session = await this.repository.findSession(
      this.crypto.digest(token),
    );
    if (!session) throw unauthorized();
    return session;
  }

  async sessions(userId: string, currentId: string) {
    return {
      sessions: (await this.repository.listSessions(userId)).map(
        ({ id, createdAt, expiresAt }) => ({
          id,
          createdAt,
          expiresAt,
          current: id === currentId,
        }),
      ),
    };
  }

  /**
   * Signed-in password change (DS-P2-003). A wrong current password is 403
   * (401 means "session expired" to clients); guesses are limited per user.
   */
  async changePassword(
    userId: string,
    sessionId: string,
    currentPassword: string,
    newPassword: string,
  ): Promise<void> {
    const retry = await this.repository.takeRateLimit(
      this.crypto.rateKey(`user:change_password:${userId}`),
      5,
      900,
    );
    if (retry > 0) {
      throw new HttpException(
        {
          error: {
            code: 'RATE_LIMITED',
            message: 'Too many attempts. Try again later.',
          },
        },
        429,
      );
    }
    const user = await this.repository.findUserById(userId);
    const valid = await this.crypto.verifyPassword(
      user?.passwordHash ?? null,
      currentPassword,
    );
    if (!valid || !user?.passwordHash) {
      throw new ForbiddenException({
        error: { code: 'INVALID_CREDENTIALS', message: 'Invalid credentials' },
      });
    }
    if (currentPassword === newPassword) {
      throw new BadRequestException({
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Choose a different password',
          details: [],
        },
      });
    }
    const changed = await this.repository.changePassword(
      userId,
      user.passwordHash,
      await this.crypto.hashPassword(newPassword),
      sessionId,
    );
    if (!changed) {
      throw new ForbiddenException({
        error: { code: 'INVALID_CREDENTIALS', message: 'Invalid credentials' },
      });
    }
  }

  revoke(userId: string, sessionId?: string) {
    return this.repository.revoke(userId, sessionId);
  }
}
